#!/usr/bin/env bash
# The checks of the reusable workflow .github/workflows/k8s-validate.yml. Each step of the workflow
# runs one step of this script with the open tools of mise.toml. A local run gives the same result:
#
#   KUSTOMIZE_ROOTS=k8s/tests/example HELM_CHARTS=charts/example \
#     PROMTOOL_RULES=k8s/components/example/rules/example.rules.yaml \
#     mise exec -- scripts/k8s-validate.sh all
#
# Steps:
#   render         kustomize build of each Kustomize root; helm dependency build, helm lint --strict
#                  and helm template of each Helm chart, once for each ci/*-values.yaml file of the
#                  chart, else once with the default values. The rendered manifests go into the
#                  folder RENDERED.
#   kubeconform    kubeconform -strict on the rendered manifests, with the CRD schemas of the
#                  datreeio CRDs-catalog.
#   kube-linter    kube-linter on the rendered manifests.
#   trivy          trivy config on the rendered manifests (HIGH and CRITICAL findings).
#   helm-unittest  helm-unittest on each Helm chart that has a tests/ folder.
#   promtool       promtool check rules on each Prometheus rule file.
#   all            each step above, in this order.
#
# Inputs (environment variables):
#   KUSTOMIZE_ROOTS, HELM_CHARTS, PROMTOOL_RULES  one path on each line, relative to the current
#                                                 folder.
#   KUBE_LINTER_CONFIG  a kube-linter config file. Empty selects the shared .kube-linter.yaml of the
#                       infra checkout that holds this script.
#   RENDERED            the folder of the rendered manifests. Empty selects a new temporary folder,
#                       which only the steps of one run share.
set -euo pipefail

infra="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
crd_schemas='https://raw.githubusercontent.com/datreeio/CRDs-catalog/main/{{.Group}}/{{.ResourceKind}}_{{.ResourceAPIVersion}}.json'

# lines TEXT: each line of TEXT that is not empty, with no space at its start or end.
lines() {
  local line
  while IFS= read -r line || [ -n "$line" ]; do
    line="${line#"${line%%[![:space:]]*}"}"
    line="${line%"${line##*[![:space:]]}"}"
    if [ -n "$line" ]; then
      printf '%s\n' "$line"
    fi
  done <<<"$1"
}

# note MESSAGE: an annotation in GitHub Actions, else a line on stderr.
note() {
  if [ -n "${GITHUB_ACTIONS-}" ]; then
    echo "::notice title=k8s-validate::$1"
  else
    echo "note: $1" >&2
  fi
}

mapfile -t roots < <(lines "${KUSTOMIZE_ROOTS-}")
mapfile -t charts < <(lines "${HELM_CHARTS-}")
mapfile -t rules < <(lines "${PROMTOOL_RULES-}")
kube_linter_config="${KUBE_LINTER_CONFIG:-$infra/.kube-linter.yaml}"
if [ -z "${RENDERED-}" ]; then
  RENDERED="$(mktemp -d)"
  trap 'rm -rf "$RENDERED"' EXIT
fi

# rendered: true when the render step wrote one or more manifest files.
rendered() {
  [ -n "$(find "$RENDERED" -name '*.yaml' -print -quit 2>/dev/null)" ]
}

render() {
  local n=0 root chart value
  local -a values args
  mkdir -p "$RENDERED"
  for root in "${roots[@]}"; do
    n=$((n + 1))
    echo "kustomize build $root"
    kustomize build --enable-helm "$root" >"$RENDERED/$n-kustomize.yaml"
  done
  for chart in "${charts[@]}"; do
    helm dependency build "$chart"
    mapfile -t values < <(find "$chart/ci" -maxdepth 1 -name '*-values.yaml' 2>/dev/null | sort)
    if [ "${#values[@]}" -eq 0 ]; then
      values=("")
    fi
    for value in "${values[@]}"; do
      n=$((n + 1))
      args=()
      if [ -n "$value" ]; then
        args=(--values "$value")
      fi
      echo "helm lint and helm template $chart ${value:-with the default values}"
      helm lint --strict "$chart" "${args[@]}"
      # Argo CD applies the CRDs of a chart and does not apply its test hooks.
      helm template "$(basename "$chart")" "$chart" "${args[@]}" --include-crds --skip-tests \
        >"$RENDERED/$n-helm.yaml"
    done
  done
  if [ "$n" -eq 0 ]; then
    note "No Kustomize root and no Helm chart, so no manifest was rendered."
  fi
}

check_kubeconform() {
  if rendered; then
    kubeconform -strict -summary -schema-location default -schema-location "$crd_schemas" "$RENDERED"
  fi
}

check_kube_linter() {
  if rendered; then
    kube-linter lint --config "$kube_linter_config" "$RENDERED"
  fi
}

check_trivy() {
  if rendered; then
    trivy config --exit-code 1 --severity HIGH,CRITICAL "$RENDERED"
  fi
}

check_helm_unittest() {
  local chart
  for chart in "${charts[@]}"; do
    if [ -d "$chart/tests" ]; then
      untt "$chart"
    else
      note "$chart has no tests/ folder, so helm unittest did not run on it."
    fi
  done
}

check_promtool() {
  if [ "${#rules[@]}" -gt 0 ]; then
    promtool check rules "${rules[@]}"
  fi
}

if [ "$#" -eq 0 ]; then
  echo "Usage: $0 render|kubeconform|kube-linter|trivy|helm-unittest|promtool|all..." >&2
  exit 2
fi
for step in "$@"; do
  case "$step" in
    render) render ;;
    kubeconform) check_kubeconform ;;
    kube-linter) check_kube_linter ;;
    trivy) check_trivy ;;
    helm-unittest) check_helm_unittest ;;
    promtool) check_promtool ;;
    all)
      render
      check_kubeconform
      check_kube_linter
      check_trivy
      check_helm_unittest
      check_promtool
      ;;
    *)
      echo "Unknown step: $step" >&2
      exit 2
      ;;
  esac
done
