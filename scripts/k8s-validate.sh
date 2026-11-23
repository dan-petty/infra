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
#                  chart, else once with the default values. Each rendered object goes into its own
#                  file of the folder RENDERED: <n>-kustomize-<root>/ or <n>-helm-<release>/, then
#                  <namespace>/ when the object has one, then <kind>-<name>.yaml. Thus each finding
#                  names one object, and an entry of a trivy ignore file can name one object.
#   kubeconform    kubeconform -strict on the rendered manifests, with the CRD schemas of the
#                  datreeio CRDs-catalog and the schema of CustomResourceDefinition.
#   kube-linter    kube-linter on the rendered manifests.
#   trivy          trivy config on the rendered manifests (HIGH and CRITICAL findings).
#   helm-unittest  helm-unittest on each Helm chart that has a tests/ folder.
#   promtool       promtool check rules on each Prometheus rule file.
#   all            each step above, in this order.
#
# A chart folder with the name test-chart is the test chart of the values template ../values.yaml
# of an upstream chart (helm/README.md). It has one dependency, the upstream chart. The steps
# render, lint and test it with the values template under the name of the dependency, as Helm gives
# values to a dependency, and as the release with the name of the dependency. Its ci/*-values.yaml
# files come after the values template.
#
# Inputs (environment variables):
#   KUSTOMIZE_ROOTS, HELM_CHARTS, PROMTOOL_RULES  one path on each line, relative to the current
#                                                 folder.
#   KUBE_LINTER_CONFIG      a kube-linter config file. Empty selects the shared .kube-linter.yaml of the
#                           infra checkout that holds this script.
#   KUBE_LINTER_IGNORE_FILE a kube-linter ignore file (the form of helm/.kubelinterignore.yaml), which
#                           holds the written judgments of the findings that the owner accepted.
#                           Empty gives no ignore file.
#   TRIVY_IGNORE_FILE       a trivy ignore file (the form of tf/.trivyignore.yaml), which trivy config
#                           gets with --ignorefile. Empty gives no ignore file.
#   RENDERED                the folder of the rendered manifests. Empty selects a new temporary folder,
#                           which only the steps of one run share.
set -euo pipefail

infra="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
crd_schemas='https://raw.githubusercontent.com/datreeio/CRDs-catalog/main/{{.Group}}/{{.ResourceKind}}_{{.ResourceAPIVersion}}.json'
# The default location of kubeconform holds the standalone schemas of yannh/kubernetes-json-schema,
# which have no schema of CustomResourceDefinition. The non-standalone schemas have it. The default
# location and the CRDs-catalog give the schema of each other kind first.
crd_schema='https://raw.githubusercontent.com/yannh/kubernetes-json-schema/master/{{.NormalizedKubernetesVersion}}/{{.ResourceKind}}{{.KindSuffix}}.json'

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
kube_linter_ignore_file="${KUBE_LINTER_IGNORE_FILE-}"
trivy_ignore_file="${TRIVY_IGNORE_FILE-}"
work="$(mktemp -d)"
if [ -z "${RENDERED-}" ]; then
  RENDERED="$work/rendered"
fi
trap 'rm -rf "$work"' EXIT

# rendered: true when the render step wrote one or more manifest files.
rendered() {
  [ -n "$(find "$RENDERED" -name '*.yaml' -print -quit 2>/dev/null)" ]
}

# chart_inputs CHART: set release to the release name of the chart CHART, and template to the
# --values arguments of its values template. A test chart (helm/README.md) gets the values template
# ../values.yaml under the name of its one dependency, in a file of the work folder, and the release
# name of the dependency. Another chart gets the release name of its folder and no values template.
chart_inputs() {
  local chart="$1" file
  release="$(basename "$chart")"
  template=()
  if [ "$release" != test-chart ]; then
    return 0
  fi
  if [ "$(yq '.dependencies | length' "$chart/Chart.yaml")" != 1 ] || [ ! -f "$chart/../values.yaml" ]; then
    echo "$chart: a test chart needs one dependency and the values template ../values.yaml" >&2
    exit 1
  fi
  release="$(yq '.dependencies[0].alias // .dependencies[0].name' "$chart/Chart.yaml")"
  file="$(mktemp "$work/values.XXXXXX")"
  NAME="$release" yq '{strenv(NAME): .}' "$chart/../values.yaml" >"$file"
  template=(--values "$file")
}

# write_objects FILE FOLDER: write each object of the manifest FILE (an absolute path) to its own
# file FOLDER/[<namespace>/]<kind>-<name>.yaml. Two objects with one file stop the step.
write_objects() {
  local path='((.metadata.namespace | select(. != null) | . + "/") // "") + .kind + "-" + .metadata.name + ".yaml"'
  local twice
  twice="$(yq ea "[select(. != null) | $path] | .[]" "$1" | sort | uniq -d)"
  if [ -n "$twice" ]; then
    echo "The render has more than one object with the file ${twice//$'\n'/, } in $2" >&2
    exit 1
  fi
  mkdir -p "$2"
  (cd "$2" && yq -s "$path" 'select(. != null)' "$1")
}

render() {
  local n=0 root chart value release
  local -a values args template
  mkdir -p "$RENDERED"
  for root in "${roots[@]}"; do
    n=$((n + 1))
    echo "kustomize build $root"
    kustomize build --enable-helm "$root" >"$work/render.yaml"
    write_objects "$work/render.yaml" "$RENDERED/$n-kustomize-$(basename "$root")"
  done
  for chart in "${charts[@]}"; do
    local repo
    repo="$(yq '.dependencies[0].repository // ""' "$chart/Chart.yaml" 2>/dev/null || true)"
    if [[ "$repo" =~ ^https?:// ]]; then
      local dep_name
      dep_name="$(yq '.dependencies[0].name' "$chart/Chart.yaml")"
      helm repo add "$dep_name" "$repo" --force-update >/dev/null 2>&1 || true
    fi
    helm dependency build "$chart"
    chart_inputs "$chart"
    mapfile -t values < <(find "$chart/ci" -maxdepth 1 -name '*-values.yaml' 2>/dev/null | sort)
    if [ "${#values[@]}" -eq 0 ]; then
      values=("")
    fi
    for value in "${values[@]}"; do
      n=$((n + 1))
      args=("${template[@]}")
      if [ -n "$value" ]; then
        args+=(--values "$value")
      fi
      echo "helm lint and helm template $chart ${value:-with the default values}"
      helm lint --strict "$chart" "${args[@]}"
      # Argo CD applies the CRDs of a chart and does not apply its test hooks.
      helm template "$release" "$chart" "${args[@]}" --include-crds --skip-tests >"$work/render.yaml"
      write_objects "$work/render.yaml" "$RENDERED/$n-helm-$release"
    done
  done
  if [ "$n" -eq 0 ]; then
    note "No Kustomize root and no Helm chart, so no manifest was rendered."
  fi
}

check_kubeconform() {
  if rendered; then
    kubeconform -strict -summary -schema-location default -schema-location "$crd_schemas" \
      -schema-location "$crd_schema" "$RENDERED"
  fi
}

check_kube_linter() {
  if [ -n "$kube_linter_ignore_file" ]; then
    if [ ! -f "$kube_linter_ignore_file" ]; then
      echo "The kube-linter ignore file $kube_linter_ignore_file does not exist." >&2
      exit 1
    fi
    if rendered; then
      local today count i check statement expired_at path_count j rel_path match_file
      today="$(date +%Y-%m-%d)"
      count="$(yq '.checks | length' "$kube_linter_ignore_file")"
      for ((i = 0; i < count; i++)); do
        check="$(yq ".checks[$i].check" "$kube_linter_ignore_file")"
        statement="$(yq ".checks[$i].statement" "$kube_linter_ignore_file")"
        expired_at="$(yq ".checks[$i].expired_at" "$kube_linter_ignore_file")"
        if [ "$today" \> "$expired_at" ]; then
          echo "The kube-linter judgment for $check expired on $expired_at" >&2
          exit 1
        fi
        path_count="$(yq ".checks[$i].paths | length" "$kube_linter_ignore_file")"
        for ((j = 0; j < path_count; j++)); do
          rel_path="$(yq ".checks[$i].paths[$j]" "$kube_linter_ignore_file")"
          while IFS= read -r match_file; do
            if [ -n "$match_file" ] && [ -f "$match_file" ]; then
              yq -i ".metadata.annotations[\"ignore-check.kube-linter.io/$check\"] = \"$statement\"" "$match_file"
            fi
          done < <(find "$RENDERED" -path "$RENDERED/$rel_path" 2>/dev/null || true)
        done
      done
    fi
  fi
  if rendered; then
    kube-linter lint --config "$kube_linter_config" "$RENDERED"
  fi
}

check_trivy() {
  local -a ignore=()
  if [ -n "$trivy_ignore_file" ]; then
    if [ ! -f "$trivy_ignore_file" ]; then
      echo "The trivy ignore file $trivy_ignore_file does not exist." >&2
      exit 1
    fi
    ignore=(--ignorefile "$trivy_ignore_file")
  fi
  if rendered; then
    trivy config --exit-code 1 --severity HIGH,CRITICAL "${ignore[@]}" "$RENDERED"
  fi
}

check_helm_unittest() {
  local chart release
  local -a template
  for chart in "${charts[@]}"; do
    if [ -d "$chart/tests" ]; then
      chart_inputs "$chart"
      untt "${template[@]}" "$chart"
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
