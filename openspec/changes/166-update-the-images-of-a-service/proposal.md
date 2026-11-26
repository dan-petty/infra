# Proposal

## Why

A new digest of a services entry never reaches the service: Argo CD Image Updater skips a service Application, because the tenant AppProject permits no Pod and no ReplicaSet, Argo CD leaves them out of the resource tree, and the Application status holds no image (#166).

## What Changes

- Add `argocd-image-updater.argoproj.io/{{ .alias }}.force-update: "true"` inside the range over the images of the `templatePatch` at `k8s/bases/service-repos/applicationsets.yaml:142:templatePatch: |`, after the update-strategy line at `k8s/bases/service-repos/applicationsets.yaml:154:argocd-image-updater.argoproj.io/{{ .alias }}.update-strategy: digest`, so each alias of an entry gets its own annotation and an entry with no images gets none.
- Assert the force-update annotation of each alias in the image branch of `tests/test-service-repos.sh`, next to the update-strategy case at `tests/test-service-repos.sh:238:has the update strategy digest for each image`.
- Change the no-other-annotation case at `tests/test-service-repos.sh:242:has no other annotation` to twice the image count plus 2, because each image now holds two annotations.
- Add a case to `tests/test-service-repos.sh` that derives a one-image entry with `yq` in the work folder and asserts its single force-update annotation.
- Add the force-update row and its reason to the annotation table at `docs/service-repos.md:99:| Annotation | Value |`.
- Keep the `namespaceResourceWhitelist` of the tenant AppProject as it is, so a service still cannot deploy a Pod or a ReplicaSet from git.
- The change fits one pull request.

## Capabilities

### New Capabilities

- `service-repos`: Force-update annotation for each image alias, Only the annotations of the images, New digest of a pushed tag

### Modified Capabilities

None.

## Impact

- Code: `k8s/bases/service-repos/applicationsets.yaml`
- Documents: `docs/service-repos.md`
- Tests: `tests/test-service-repos.sh`

## Feasibility

- The probes say, word for word: The path `tests/test-service-repos.sh` is a file of the staging commit. The path `k8s/bases/service-repos/applicationsets.yaml` is a file of the staging commit. The path `docs/service-repos.md` is a file of the staging commit.
- The probes say, word for word: The path `status.summary.images` is no file of the staging commit. No commit in the history deleted or renamed it. The probes say the same of `spec.source.kustomize.images` and `argocd-image-updater.argoproj`, so those are two fields and an annotation prefix of an Application, not a path that a commit removed.
- `read_file k8s/bases/service-repos/appproject.yaml` lines 30 to 70 showed `k8s/bases/service-repos/appproject.yaml:38:namespaceResourceWhitelist:` with AppProject, NetworkPolicy, LimitRange, Middleware, ServiceAccount, Role, RoleBinding, SecretStore, the five store kinds, ExternalSecret, PushSecret and Password, and no Pod and no ReplicaSet, which confirms the premise of the issue.
- `read_file charts/service-tenant/templates/appproject.yaml` lines 55 to 80 showed that the tenant AppProject writes its allow-list from the kinds of the entry at `charts/service-tenant/templates/appproject.yaml:64:namespaceResourceWhitelist:`, so that list decides which kinds the project permits.
- `read_file k8s/bases/service-repos/applicationsets.yaml` lines 125 to 165 showed `k8s/bases/service-repos/applicationsets.yaml:142:templatePatch: |`, the range over the images at `k8s/bases/service-repos/applicationsets.yaml:146:{{- range .images }}` and the per-alias strategy at `k8s/bases/service-repos/applicationsets.yaml:154:argocd-image-updater.argoproj.io/{{ .alias }}.update-strategy: digest`, so the force-update line goes into that same range.
- `read_file tests/test-service-repos.sh` lines 215 to 265 showed the image branch at `tests/test-service-repos.sh:233:if [ "$(yq '.images // [] | length' "$entry")" -gt 0 ]; then`, the update-strategy case at `tests/test-service-repos.sh:238:has the update strategy digest for each image`, the no-other-annotation case at `tests/test-service-repos.sh:242:has no other annotation` and its count at `tests/test-service-repos.sh:243:"$(yq '.images | length + 2' "$entry")"`, so the count becomes twice the image count plus 2.
- `read_file k8s/tests/service-repos/services/example.yaml` showed the two aliases at `k8s/tests/service-repos/services/example.yaml:14:- alias: web`, and `list_files k8s/tests/service-repos/services` listed `example.yaml` and `minimal.yaml`, so the only entry with images holds two aliases and the one-image case derives its entry with `yq` in the work folder.
- `read_file docs/service-repos.md` lines 88 to 118 showed the annotation table at `docs/service-repos.md:99:| Annotation | Value |` with the image-list, update-strategy and write-back-method rows and no force-update row, and the sentence at `docs/service-repos.md:97:entry with one or more images` that introduces that table.
- `search_code` for `test-service-repos.sh` answered `.github/workflows/ci.yml:298:run: mise exec -- tests/test-service-repos.sh` and `README.md:281:| K8s templates |`, and `read_file .github/workflows/ci.yml` lines 288 to 302 showed the job installs kustomize, yq, helm and kubeconform with `mise install --locked`, so the job runs the test that the first group changes.
- `references` for `force-update` answered `files 1, lines 1` with `scripts/k8s-validate.sh: 1 (line 140)`, and `read_file scripts/k8s-validate.sh` lines 136 to 143 showed `scripts/k8s-validate.sh:140:helm repo add "$dep_name" "$repo" --force-update >/dev/null 2>&1 || true`, the flag of `helm repo add` and no annotation of Image Updater, so that script stays as it is.
- `read_file k8s/bases/service-repos/imageupdater.yaml` showed the ImageUpdater object `service-repos` with `k8s/bases/service-repos/imageupdater.yaml:19:useAnnotations: true`, so the per-alias force-update annotation is the setting that Image Updater reads.
- `read_spec ci-check-names` answered one capability with one requirement, so no capability covers the service Applications and `service-repos` is new; `list_files` of the repository root listed no `src` directory, so no behavior group and no Python test exists here.
- The finding is fixed at its place: each of the three flagged scenarios now names a live check command with `kubectl` and names no file of the repository, so no scenario names a test module that only a behavior group could cover; the earlier scenarios named `tests/test-service-repos.sh`, and this repository holds no `src` directory for a behavior group.
- The annotation set is counted by the case at `tests/test-service-repos.sh:242:has no other annotation`, whose expected length becomes twice the image count plus 2, which is 6 for the entry with the aliases web and worker; the plan restricts the set to the four annotations of the images and removes nothing else.
- The plan calls no function whose arguments need a checkout of the repository, a client of a service or a network.
- The plan introduces no command and no verify program: `mise` is not in the runner tool list, `helm`, `kustomize` and `kubeconform` are `NOT_IN_RUNNER`, and `yq` is not listed, so the test runs on a workstation only; the live checks need a cluster and a person, and no step of the plan runs in the pod, needs a cluster token or reaches the network.
- The first checks against the real system are `mise install --locked` and `mise exec -- tests/test-service-repos.sh` on a workstation, the command of the job at `.github/workflows/ci.yml:298:run: mise exec -- tests/test-service-repos.sh`, and after the merge `kubectl -n argocd logs deploy/argocd-image-updater` and `kubectl -n argocd get application -o yaml`.
- The live observations of the issue, the log line `images_considered=0 images_skipped=1` and the empty `status.summary.images` of the service Application, are not checked: this run reads the repository only and reaches no cluster.
- `read_issue 163` answered closed (completed), and the patch block of that work is in the staged file at `k8s/bases/service-repos/applicationsets.yaml:158:{{- if hasKey . "patches" }}`, so no issue must be delivered first and the plan needs no dependency entry.
- The issue can be built as written: option 1 adds no permission, and the allow-list of the tenant AppProject stays as it is.

## Existing Tool Considered

argoproj-labs/argocd-image-updater (Apache-2.0, maintained) already runs for `service-repos` at `k8s/bases/service-repos/imageupdater.yaml`; the change uses its per-alias force-update annotation and builds no code.

## Dependencies

None.
