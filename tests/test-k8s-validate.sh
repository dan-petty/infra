#!/usr/bin/env bash
# Tests of scripts/k8s-validate.sh. Run it with `mise exec -- tests/test-k8s-validate.sh`. It runs
# the script with kustomize, helm, yq, kubeconform and trivy.
#
# The cases: a test chart renders its one dependency with the values template of its folder; the
# render writes each object to its own file; kubeconform accepts a CustomResourceDefinition; and
# the trivy ignore file helm/.trivyignore.yaml admits only the findings that the owner accepted, on
# the objects that it names.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
validate="$root/scripts/k8s-validate.sh"
ignore="$root/helm/.trivyignore.yaml"
kl_ignore="$root/helm/.kubelinterignore.yaml"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
failures=0
cases=0

pass() {
  cases=$((cases + 1))
  echo "ok   $1"
}

fail() {
  cases=$((cases + 1))
  failures=$((failures + 1))
  echo "FAIL $1"
  if [ -f "$work/log" ]; then
    sed 's/^/     /' "$work/log" | tail -20
  fi
}

# run WANT NAME COMMAND...: run COMMAND and compare its exit code with WANT.
run() {
  local want="$1" name="$2" got=0
  shift 2
  "$@" >"$work/log" 2>&1 || got=$?
  if [ "$got" -eq "$want" ]; then
    pass "$name"
  else
    fail "$name: exit $got, want $want"
  fi
}

# says NAME TEXT: the output of the last run has the line TEXT.
says() {
  if grep -qF -- "$2" "$work/log"; then
    pass "$1"
  else
    fail "$1: the output has no line $2"
  fi
}

# expect NAME FILE EXPRESSION WANT: the yq expression EXPRESSION on FILE gives the text WANT.
expect() {
  local got
  got="$(yq "$3" "$2" 2>&1)" || true
  if [ "$got" = "$4" ]; then
    pass "$1"
  else
    fail "$1: got $got, want $4"
  fi
}

# The test chart of a values template, with the chart charts/example as its dependency.
template="$work/helm/demo"
mkdir -p "$template/test-chart/templates"
printf 'host: template.example.com\n' >"$template/values.yaml"
printf '{}\n' >"$template/test-chart/values.yaml"
cat >"$template/test-chart/Chart.yaml" <<EOF
apiVersion: v2
name: test-chart
version: 0.1.0
dependencies:
  - name: example
    version: 0.1.0
    repository: file://$root/charts/example
EOF
out="$work/test-chart"
run 0 "a test chart renders" env HELM_CHARTS="$template/test-chart" RENDERED="$out" "$validate" render
expect "a test chart renders its dependency with the values template, as a release of the dependency" \
  "$out/1-helm-example/ConfigMap-example-example.yaml" '.data.url' 'https://template.example.com/'

# A test chart with two dependencies has no one name for the values template.
yq -i '.dependencies += [.dependencies[0] | .alias = "second"]' "$template/test-chart/Chart.yaml"
rm -rf "$template/test-chart/Chart.lock" "$template/test-chart/charts"
run 1 "a test chart with two dependencies stops the render" \
  env HELM_CHARTS="$template/test-chart" RENDERED="$work/two" "$validate" render
says "the render names the rule of a test chart" "a test chart needs one dependency and the values template"

out="$work/kustomize"
run 0 "a Kustomize root renders" env KUSTOMIZE_ROOTS="$root/k8s/tests/example/" RENDERED="$out" "$validate" render
expect "the render writes each object to the file <namespace>/<kind>-<name>.yaml" \
  "$out/1-kustomize-example/example/PersistentVolumeClaim-example.yaml" '.kind + "/" + .metadata.name' \
  'PersistentVolumeClaim/example'
files="$(find "$out" -type f -name '*.yaml' | wc -l)"
objects="$(kustomize build "$root/k8s/tests/example" | yq ea '[.] | length')"
if [ "$files" -eq "$objects" ]; then
  pass "the render writes one file for each object"
else
  fail "the render writes one file for each object: $files files, $objects objects"
fi
out="$work/service-tenant"
run 0 "a chart renders" env HELM_CHARTS="$root/charts/service-tenant" RENDERED="$out" "$validate" render
expect "the render writes a namespaced object to the folder of its namespace" \
  "$out/2-helm-service-tenant/example-db/NetworkPolicy-default-deny-ingress.yaml" '.metadata.namespace' 'example-db'

# Two objects with one kind, namespace and name would write one file.
twice="$work/twice"
mkdir -p "$twice/templates"
printf 'apiVersion: v2\nname: twice\nversion: 0.1.0\n' >"$twice/Chart.yaml"
printf '{}\n' >"$twice/values.yaml"
for _ in 1 2; do
  printf -- '---\napiVersion: v1\nkind: ConfigMap\nmetadata:\n  name: same\n'
done >"$twice/templates/configmaps.yaml"
run 1 "two objects with one file stop the render" env HELM_CHARTS="$twice" RENDERED="$work/twice-out" "$validate" render
says "the render names the file of the two objects" "more than one object with the file ConfigMap-same.yaml"

# kubeconform finds the schema of a CustomResourceDefinition.
mkdir -p "$work/crd"
cat >"$work/crd/crd.yaml" <<'EOF'
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: widgets.example.com
spec:
  group: example.com
  names:
    kind: Widget
    plural: widgets
  scope: Namespaced
  versions:
    - name: v1
      served: true
      storage: true
      schema:
        openAPIV3Schema:
          type: object
EOF
run 0 "kubeconform accepts a CustomResourceDefinition" env RENDERED="$work/crd" "$validate" kubeconform

# cluster_role FOLDER NAME RESOURCE: write a ClusterRole NAME that can update RESOURCE to the render
# folder FOLDER, as the render step does.
cluster_role() {
  rm -rf "$work/trivy"
  mkdir -p "$work/trivy/$1"
  {
    printf 'apiVersion: rbac.authorization.k8s.io/v1\nkind: ClusterRole\nmetadata:\n  name: %s\n' "$2"
    if [ "$3" = secrets ]; then
      printf 'rules:\n  - apiGroups: [""]\n    resources: [secrets]\n    verbs: [get, update]\n'
    else
      printf 'rules:\n  - apiGroups: [admissionregistration.k8s.io]\n    resources: [%s]\n    verbs: [update]\n' "$3"
    fi
  } >"$work/trivy/$1/ClusterRole-$2.yaml"
}

trivy_step() {
  env RENDERED="$work/trivy" TRIVY_IGNORE_FILE="$ignore" "$validate" trivy
}

cluster_role 1-helm-external-secrets external-secrets-controller secrets
run 0 "trivy: the accepted KSV-0041 on ClusterRole external-secrets-controller passes" trivy_step
cluster_role 1-helm-external-secrets external-secrets-cert-controller secrets
run 0 "trivy: the accepted KSV-0041 on ClusterRole external-secrets-cert-controller passes" trivy_step
cluster_role 1-helm-external-secrets external-secrets-cert-controller validatingwebhookconfigurations
run 0 "trivy: the accepted KSV-0114 on ClusterRole external-secrets-cert-controller passes" trivy_step
cluster_role 1-helm-external-secrets external-secrets-controller validatingwebhookconfigurations
run 1 "trivy: KSV-0114 on ClusterRole external-secrets-controller fails" trivy_step
cluster_role 1-helm-external-secrets external-secrets-view secrets
run 1 "trivy: KSV-0041 on another ClusterRole of the release fails" trivy_step
cluster_role 1-helm-other external-secrets-controller secrets
run 1 "trivy: KSV-0041 on ClusterRole external-secrets-controller of another release fails" trivy_step
cluster_role 1-helm-external-secrets external-secrets-controller secrets
run 1 "trivy: the findings fail with no ignore file" env RENDERED="$work/trivy" "$validate" trivy
run 1 "trivy: an ignore file that does not exist stops the step" \
  env RENDERED="$work/trivy" TRIVY_IGNORE_FILE="$work/no-file.yaml" "$validate" trivy
says "trivy: the step names the ignore file that does not exist" "$work/no-file.yaml does not exist"

# workload FOLDER KIND NAME: write a workload KIND NAME with no probe to the render folder FOLDER.
workload() {
  rm -rf "$work/kube-linter"
  mkdir -p "$work/kube-linter/$1"
  local extra=""
  if [ "$2" = "StatefulSet" ]; then
    extra="serviceName: $3-headless"
  else
    extra="strategy:
    type: RollingUpdate"
  fi
  cat >"$work/kube-linter/$1/$2-$3.yaml" <<EOF
apiVersion: apps/v1
kind: $2
metadata:
  name: $3
spec:
  replicas: 1
  $extra
  selector:
    matchLabels:
      app: $3
  template:
    metadata:
      labels:
        app: $3
    spec:
      serviceAccountName: default
      automountServiceAccountToken: false
      securityContext:
        runAsNonRoot: true
        seccompProfile:
          type: RuntimeDefault
      containers:
        - name: app
          image: app:1.0.0
          securityContext:
            allowPrivilegeEscalation: false
            readOnlyRootFilesystem: true
            capabilities:
              drop:
                - ALL
          resources:
            requests:
              cpu: 100m
              memory: 128Mi
            limits:
              memory: 128Mi
          ports:
            - containerPort: 8080
          readinessProbe:
            httpGet:
              path: /ready
              port: 8080
EOF
  cat >"$work/kube-linter/$1/NetworkPolicy-$3.yaml" <<EOF
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: $3
spec:
  podSelector: {}
  policyTypes:
    - Ingress
    - Egress
EOF
}

kl_step() {
  env RENDERED="$work/kube-linter" KUBE_LINTER_IGNORE_FILE="$kl_ignore" "$validate" kube-linter
}

workload 1-helm-mattermost-operator Deployment mattermost-operator
run 0 "kube-linter: the accepted no-liveness-probe on Deployment mattermost-operator passes" kl_step
workload 1-helm-pyroscope StatefulSet pyroscope
run 0 "kube-linter: the accepted no-liveness-probe on StatefulSet pyroscope passes" kl_step
workload 1-helm-other StatefulSet other-workload
run 1 "kube-linter: no-liveness-probe on StatefulSet other-workload fails" kl_step
workload 1-helm-pyroscope StatefulSet pyroscope
run 1 "kube-linter: the finding fails with no ignore file" env RENDERED="$work/kube-linter" "$validate" kube-linter
run 1 "kube-linter: an ignore file that does not exist stops the step" \
  env RENDERED="$work/kube-linter" KUBE_LINTER_IGNORE_FILE="$work/no-kl-file.yaml" "$validate" kube-linter
says "kube-linter: the step names the ignore file that does not exist" "$work/no-kl-file.yaml does not exist"

echo "$((cases - failures)) of $cases cases passed"
[ "$failures" -eq 0 ]
