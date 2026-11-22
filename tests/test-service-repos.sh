#!/usr/bin/env bash
# Tests of the base k8s/bases/service-repos (docs/service-repos.md) with its test overlay
# k8s/tests/service-repos. Run it with `mise exec -- tests/test-service-repos.sh`. It runs kustomize,
# yq, helm and, through scripts/k8s-validate.sh, kubeconform.
#
# The first checks read the fields of the rendered overlay. The next checks render the Application
# templates of the two ApplicationSets for each services entry of k8s/tests/service-repos/services/.
# Only the ApplicationSet controller of Argo CD runs the generators, and `argocd appset generate`
# needs an Argo CD server. Thus the test gives the template and the templatePatch of each set to
# `helm template`, which also runs Go templates with the sprig functions. The params are the keys of
# the entry and the path of its file under the pathParamPrefix of the Git files generator
# (applicationset/generators/repo_path_utils.go of Argo CD v3.6.2). The test merges the patch into
# the Application, checks each Application with kubeconform, and renders the chart
# charts/service-tenant with the value files of each tenant Application.
#
# Limits: Argo CD renders each string of the template alone, and `helm template` renders the
# template as one text. The test entries hold no character that this changes. `helm template` has
# no missingkey=error: a missing key gives an empty string. Thus the test refuses an empty string in
# an Application, and one case shows that an entry with no path gives one.
#
# The yq expressions and the expected values in single quotes hold $ for the variables of yq and for
# the text $values of Argo CD, not for the shell.
# shellcheck disable=SC2016
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
overlay="$root/k8s/tests/service-repos"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
failures=0
cases=0

guard='{{- if hasKey . "images" }}'
empty='[.. | select(tag == "!!str" and . == "")] | length'
annotation='.metadata.annotations["argocd-image-updater.argoproj.io/'

pass() {
  cases=$((cases + 1))
  echo "ok   $1"
}

fail() {
  cases=$((cases + 1))
  failures=$((failures + 1))
  echo "FAIL $1"
}

# expect NAME FILE EXPRESSION WANT: the yq expression EXPRESSION on the one document of FILE gives
# the yq value WANT. yq compares maps and lists by reference, so the test compares their JSON with
# sorted keys.
expect() {
  local name="$1" file="$2" expression="$3" want="$4" got wanted
  got="$(yq "$expression | sort_keys(..) | to_json(0)" "$file" 2>&1)" || true
  wanted="$(yq -n "$want | sort_keys(..) | to_json(0)" 2>&1)" || true
  if [ "$got" = "$wanted" ]; then
    pass "$name"
  else
    fail "$name: got $got, want $wanted"
  fi
}

# object KIND NAME: write the object KIND/NAME of the rendered overlay to the work folder as
# NAME.yaml. The overlay must have exactly one.
object() {
  local selector="select(.kind == \"$1\" and .metadata.name == \"$2\")" count
  count="$(yq ea "[$selector] | length" "$rendered")"
  if [ "$count" -ne 1 ]; then
    fail "the overlay has $count objects $1/$2, want 1"
  fi
  yq ea "$selector" "$rendered" >"$work/$2.yaml"
}

rendered="$work/overlay.yaml"
kustomize build "$overlay" >"$rendered"
object ApplicationSet service-tenants
object ApplicationSet service-workloads
object AppProject services-admin
object ImageUpdater service-repos
tenants="$work/service-tenants.yaml"
workloads="$work/service-workloads.yaml"
project="$work/services-admin.yaml"
updater="$work/service-repos.yaml"

for set in service-tenants service-workloads; do
  s="$work/$set.yaml"
  expect "$set: Go templates with missingkey=error" "$s" \
    '[.spec.goTemplate, .spec.goTemplateOptions]' '[true, ["missingkey=error"]]'
  # Argo CD adds the resources finalizer only when preserveResourcesOnDeletion is false. A
  # finalizer in the template deletes the resources of the Application although the option is set.
  expect "$set: preserveResourcesOnDeletion and no resources finalizer" "$s" \
    '[.spec.syncPolicy.preserveResourcesOnDeletion, .spec.template.metadata.finalizers]' '[true, null]'
  expect "$set: one Git files generator over k8s/services/*.yaml with a pathParamPrefix" "$s" \
    '[.spec.generators[] | [.git.repoURL, .git.files, .git.pathParamPrefix]]' \
    '[["https://git.example.com/environment.git", [{"path": "k8s/services/*.yaml"}], "file"]]'
  # The AppProject of the tenant chart has the on-deployed subscription of the notifications.
  expect "$set: no annotation in the template" "$s" '.spec.template.metadata.annotations' 'null'
  expect "$set: the template reads no images" "$s" \
    '[.spec.template | .. | select(tag == "!!str") | select(test("images"))]' '[]'
done

expect "service-tenants: project services-admin" "$tenants" '.spec.template.spec.project' '"services-admin"'
expect "service-tenants: the chart pin is the release of version.txt" "$tenants" \
  '.spec.template.spec.sources[0] | [.repoURL, .path, .targetRevision]' \
  "[\"https://github.com/dan-petty/infra.git\", \"charts/service-tenant\", \"v$(cat "$root/version.txt")\"]"
expect "service-tenants: the platform values, then the entry file through the pathParamPrefix" "$tenants" \
  '.spec.template.spec.sources[0].helm.valueFiles' \
  '["$values/k8s/argocd/services/tenant-values.yaml", "$values/{{ .file.path.path }}/{{ .file.path.filename }}"]'
expect "service-tenants: the values source of the environment repository" "$tenants" \
  '.spec.template.spec.sources[1]' \
  '{"repoURL": "https://git.example.com/environment.git", "targetRevision": "HEAD", "ref": "values"}'
expect "service-tenants: FailOnSharedResource, so two entries cannot take one object" "$tenants" \
  '.spec.template.spec.syncPolicy.syncOptions' '["FailOnSharedResource=true"]'
expect "service-tenants: no templatePatch" "$tenants" '.spec.templatePatch' 'null'

expect "service-workloads: Argo CD keeps the images that Image Updater writes" "$workloads" \
  '.spec.ignoreApplicationDifferences' '[{"jsonPointers": ["/spec/source/kustomize/images"]}]'
expect "service-workloads: the templatePatch starts with the guard of images and ends with its end" \
  "$workloads" '.spec.templatePatch | split("\n") | map(select(test("\\S"))) | [.[0], .[-1]]' \
  "[$(GUARD="$guard" yq -n 'strenv(GUARD) | to_json(0)'), \"{{- end }}\"]"

expect "services-admin: the sources of the tenant chart and the entries" "$project" '.spec.sourceRepos' \
  '["https://github.com/dan-petty/infra.git", "https://git.example.com/environment.git"]'
expect "services-admin: Namespace is the only cluster-scoped kind" "$project" \
  '.spec.clusterResourceWhitelist' '[{"group": "", "kind": "Namespace"}]'
expect "services-admin: argocd for the AppProjects, and each namespace but the reserved ones" "$project" \
  '[.spec.destinations[] | .namespace]' \
  '["argocd", "*", "!kube-system", "!kube-public", "!kube-node-lease", "!default", "!monitoring"]'

expect "service-repos: in argocd, with only the label selector and the annotation mode" "$updater" \
  '[.metadata.namespace, .spec]' \
  '["argocd", {"applicationRefs": [{"namePattern": "*", "useAnnotations": true,
    "labelSelectors": {"matchLabels": {"app.kubernetes.io/part-of": "service-repos"}}}]}]'

# The render of the templates, in a chart with one template file for the template of the set and one
# for its templatePatch.
prefix="$(yq '.spec.generators[0].git.pathParamPrefix' "$workloads")"
dir="$(dirname "$(yq '.spec.generators[0].git.files[0].path' "$workloads")")"
chart="$work/render"
mkdir -p "$chart/templates" "$work/applications"
printf 'apiVersion: v2\nname: render\nversion: 0.1.0\n' >"$chart/Chart.yaml"

# generate SET ENTRY OUT: write to OUT the Application that the ApplicationSet SET generates from the
# entry file ENTRY. A template error stops the test.
generate() {
  local set="$work/$1.yaml" entry="$2" out="$3"
  {
    echo '{{- with .Values }}'
    printf 'apiVersion: argoproj.io/v1alpha1\nkind: Application\n'
    yq '.spec.template' "$set"
    echo '{{- end }}'
  } >"$chart/templates/application.yaml"
  {
    echo '{{- with .Values }}'
    yq '.spec.templatePatch // ""' "$set"
    echo '{{- end }}'
  } >"$chart/templates/patch.yaml"
  # The params of the Git files generator with goTemplate: the keys of the entry, and the path of
  # the entry file under the pathParamPrefix.
  PREFIX="$prefix" DIR="$dir" FILE="$(basename "$entry")" yq '.[strenv(PREFIX)] = {"path": {
      "path": strenv(DIR), "basename": (strenv(DIR) | split("/") | .[-1]), "filename": strenv(FILE),
      "segments": (strenv(DIR) | split("/"))}}' "$entry" >"$work/params.yaml"
  rm -rf "$work/out"
  helm template render "$chart" --values "$work/params.yaml" --output-dir "$work/out" >/dev/null
  # helm writes no file for a template that renders no text.
  if [ -f "$work/out/render/templates/patch.yaml" ]; then
    yq ea '. as $item ireduce ({}; . * $item)' "$work/out/render/templates/application.yaml" \
      "$work/out/render/templates/patch.yaml" >"$out"
  else
    yq '.' "$work/out/render/templates/application.yaml" >"$out"
  fi
}

# not_permitted CHART: the objects of the rendered chart CHART that the AppProject services-admin
# refuses, as a JSON list of "group/kind namespace": a kind of no allow-list, or a namespace that no
# destination admits or that a deny destination refuses.
not_permitted() {
  yq ea '[{"file": fi, "object": .}] |
    ([.[] | select(.file == 0) | .object][0]) as $p |
    [$p.spec.clusterResourceWhitelist[] | .group + "/" + .kind] as $cluster |
    [$p.spec.namespaceResourceWhitelist[] | .group + "/" + .kind] as $namespaced |
    [$p.spec.destinations[] | .namespace] as $destinations |
    [.[] | select(.file == 1) | .object |
      {"key": ((.apiVersion | sub("/?[^/]+$", "")) + "/" + .kind), "namespace": .metadata.namespace}] |
    map(select(
      (.namespace == null and (.key as $k | $cluster | any_c(. == $k) | not)) or
      (.namespace != null and (
        (.key as $k | $namespaced | any_c(. == $k) | not) or
        (.namespace as $n | $destinations | any_c(. == "!" + $n)) or
        (.namespace as $n | $destinations | any_c(. == "*" or . == $n) | not)))
    ) | .key + " " + (.namespace // "")) | to_json(0)' "$project" "$1"
}

for entry in "$overlay"/services/*.yaml; do
  file="$(basename "$entry")"
  name="$(yq '.name' "$entry")"
  tenant="$work/applications/tenant-$name.yaml"
  workload="$work/applications/$name.yaml"
  generate service-tenants "$entry" "$tenant"
  generate service-workloads "$entry" "$workload"

  expect "$file: tenant-$name has no empty field" "$tenant" "$empty" '0'
  expect "$file: $name has no empty field" "$workload" "$empty" '0'
  expect "$file: tenant-$name in services-admin, with the platform values and the entry file" "$tenant" \
    '[.metadata.name, .spec.project, .spec.sources[0].helm.valueFiles]' \
    "[\"tenant-$name\", \"services-admin\",
      [\"\$values/k8s/argocd/services/tenant-values.yaml\", \"\$values/$dir/$file\"]]"
  expect "$file: $name deploys the source of the entry into its first namespace" "$workload" \
    '[.metadata.name, .metadata.labels["app.kubernetes.io/part-of"], .spec.project, .spec.source.repoURL,
      .spec.source.path, .spec.source.targetRevision, .spec.destination.namespace]' \
    "$(yq '[.name, "service-repos", .name, .repoURL, .path, .targetRevision, .namespaces[0].name] |
      to_json(0)' "$entry")"
  if [ "$(yq '.images // [] | length' "$entry")" -gt 0 ]; then
    expect "$file: $name has the image list of the entry" "$workload" "${annotation}image-list\"]" \
      "$(yq '[.images[] | .alias + "=" + .image] | join(",") | to_json(0)' "$entry")"
    expect "$file: $name has the write-back method argocd" "$workload" \
      "${annotation}write-back-method\"]" '"argocd"'
    expect "$file: $name has the update strategy digest for each image" "$workload" \
      '[.metadata.annotations | to_entries[] | select(.key | test("\\.update-strategy$"))] | from_entries' \
      "$(yq '[.images[] | {"key": "argocd-image-updater.argoproj.io/" + .alias + ".update-strategy",
        "value": "digest"}] | from_entries | to_json(0)' "$entry")"
    expect "$file: $name has no other annotation" "$workload" '.metadata.annotations | length' \
      "$(yq '.images | length + 2' "$entry")"
  else
    expect "$file: $name has no annotation" "$workload" '.metadata.annotations' 'null'
  fi

  # The chart renders with the value files of the tenant Application, from the test copy of the
  # environment repository: the platform values in tenant-values.yaml, then the entry file.
  values=()
  while IFS= read -r value; do
    case "$value" in
      "\$values/k8s/argocd/services/tenant-values.yaml") values+=(--values "$overlay/tenant-values.yaml") ;;
      "\$values/$dir/$file") values+=(--values "$entry") ;;
      *) values+=(--values "$work/unknown-value-file") ;;
    esac
  done < <(yq '.spec.sources[0].helm.valueFiles[]' "$tenant")
  if helm template "tenant-$name" "$root/charts/service-tenant" "${values[@]}" \
    >"$work/chart-$name.yaml" 2>"$work/chart.log"; then
    pass "$file: the chart renders with the value files of tenant-$name"
  else
    fail "$file: the chart renders with the value files of tenant-$name: $(cat "$work/chart.log")"
  fi
  refused="$(not_permitted "$work/chart-$name.yaml")"
  if [ "$refused" = '[]' ]; then
    pass "$file: services-admin permits each object of the chart"
  else
    fail "$file: services-admin permits each object of the chart: it refuses $refused"
  fi
done

# The check of empty fields finds a missing key, which missingkey=error refuses in Argo CD.
yq 'del(.path)' "$overlay/services/minimal.yaml" >"$work/no-path.yaml"
generate service-workloads "$work/no-path.yaml" "$work/no-path-application.yaml"
expect "an entry with no path gives one empty field" "$work/no-path-application.yaml" "$empty" '1'
# The guard writes no annotation for an empty list of images.
yq '.images = []' "$overlay/services/minimal.yaml" >"$work/no-images.yaml"
generate service-workloads "$work/no-images.yaml" "$work/no-images-application.yaml"
expect "an entry with an empty list of images gives no annotation" "$work/no-images-application.yaml" \
  '.metadata.annotations' 'null'

if RENDERED="$work/applications" "$root/scripts/k8s-validate.sh" kubeconform; then
  pass "kubeconform accepts each generated Application"
else
  fail "kubeconform accepts each generated Application"
fi

echo "$((cases - failures)) of $cases cases passed"
[ "$failures" -eq 0 ]
