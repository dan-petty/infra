# Design

## Decisions

- **Write the force-update annotation in the `templatePatch` of `service-workloads`, one per image alias.**: It changes no permission, and the templatePatch already writes the per-alias update strategy at `k8s/bases/service-repos/applicationsets.yaml:154:argocd-image-updater.argoproj.io/{{ .alias }}.update-strategy: digest`.
- **Keep the `namespaceResourceWhitelist` of the tenant AppProject as it is.**: Adding Pod and ReplicaSet changes an allow-list and lets a service deploy them from git, and the issue gives that choice to the owner.
- **Write the annotation value as the quoted string `"true"`.**: An annotation value is a string, and the templatePatch writes the update strategy of each alias in the same range, so an unquoted true would be a YAML boolean.
- **Prove each scenario of the spec with a live check command that starts with `kubectl`, and name no file of the repository in a scenario.**: The repository holds no `src` directory, so no behavior group covers a file of the test suite; the shell test is the check of group 1, and the scenarios state what a person sees on the cluster.
- **Start the live checks after the infra release that holds the change, the bump of the `?ref=` of the consumer and the Argo CD sync.**: The consumer builds the base at a release tag of infra (`docs/service-repos.md:135`), so the cluster shows no annotation right after the merge.
- **Accept one rollout when the annotation lands.**: `spec.source.kustomize` of a service Application is empty, so the first cycle of Image Updater writes the current digest of each alias, and Argo CD rolls the Deployments of the entry once.
- **Keep both groups `other` and prove each with a `process`.**: The repository holds no `src` directory, and the test needs `helm`, `kustomize`, `kubeconform` and `yq`, of which the first three are `NOT_IN_RUNNER` and the last is not listed, so the command runs on a workstation.
- **Derive the one-image entry of the test with `yq` into the work folder.**: `k8s/tests/service-repos/services/example.yaml:14:- alias: web` holds two aliases, and the overlay holds one other entry, so no test entry holds exactly one image.
- **Keep `scripts/k8s-validate.sh` as it is.**: Its only `force-update` text is `scripts/k8s-validate.sh:140:helm repo add "$dep_name" "$repo" --force-update >/dev/null 2>&1 || true`, which is no annotation of Image Updater.
- **Keep `README.md`, `.github/workflows/ci.yml` and the overlay of `k8s/tests/service-repos` as they are.**: The check table of `README.md:289:| K8s templates |` already names the test command, the job at `.github/workflows/ci.yml:298:run: mise exec -- tests/test-service-repos.sh` runs it, and the overlay lists no new resource.

## Rejected alternatives

- **Add Pod and ReplicaSet to the `namespaceResourceWhitelist` of the tenant AppProject.**: It changes an allow-list and lets a service deploy a Pod and a ReplicaSet from git; the `$kinds` list of the tenant chart at `charts/service-tenant/templates/appproject.yaml:10` names neither kind, and the issue gives that choice to the owner.
- **Wait for `status.summary.images` of the service Application to hold the images.**: The `$kinds` list of the tenant chart at `charts/service-tenant/templates/appproject.yaml:10` holds no Pod and no ReplicaSet, so Argo CD leaves them out of the resource tree and the status stays empty.
- **Prove the template change with a schema check of the ApplicationSet document alone.**: `k8s/bases/service-repos/applicationsets.yaml:142:templatePatch: |` holds the annotation as a Go template string, so a schema check of the document renders no annotation.
- **Write a behavior group and a Python test for the annotation.**: `list_files` of the repository root listed no `src` directory, and `helm`, `kustomize` and `kubeconform` are `NOT_IN_RUNNER`, so the plan extends `tests/test-service-repos.sh` and proves it with a manual check instead.
- **Name the shell test command `mise exec -- tests/test-service-repos.sh` in a spec scenario.**: A scenario states behavior that a person sees on the cluster; the shell test is a check of the rendered template, and group 1 runs it.

## Security

The change adds one annotation key to the Application that Argo CD Image Updater reads, and it crosses no trust boundary: it grants no permission, creates no resource and adds no network path. The `namespaceResourceWhitelist` of the tenant AppProject stays as it is, so a service still cannot deploy a Pod or a ReplicaSet from git. A person confirms on the cluster that only Image Updater writes `spec.source.kustomize.images`, because the annotation enables that write. The case `has no other annotation` of `tests/test-service-repos.sh` fails when an Application of a services entry holds an annotation other than the image list, the write-back method, the update strategy and the force-update annotations of its images.
