# Proposal

## Why

A new digest of a services entry never reaches the service: Argo CD Image Updater skips a service Application, because the tenant AppProject permits no Pod and no ReplicaSet, Argo CD leaves them out of the resource tree, and the Application status holds no image (#166).

## What Changes

- Add `argocd-image-updater.argoproj.io/{{ .alias }}.force-update: "true"` inside the range over the images of the `templatePatch` at `k8s/bases/service-repos/applicationsets.yaml:142:templatePatch: |`, after the update-strategy line at `k8s/bases/service-repos/applicationsets.yaml:154:argocd-image-updater.argoproj.io/{{ .alias }}.update-strategy: digest`, so each alias of an entry gets its own annotation and an entry with no images gets none.
- Assert the force-update annotation of each alias in the image branch of `tests/test-service-repos.sh`, next to the update-strategy case at `tests/test-service-repos.sh:238:has the update strategy digest for each image`.
- Change the no-other-annotation case at `tests/test-service-repos.sh:242:has no other annotation` to the yq expression `.images | (length * 2) + 2`, because each image now holds two annotations.
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
- The service Application uses `project: '{{.name}}'` at `k8s/bases/service-repos/applicationsets.yaml:117`, the AppProject of the tenant chart. Its allow-list is the `$kinds` list at `charts/service-tenant/templates/appproject.yaml:10` to line 31, which names Deployment, StatefulSet, PodDisruptionBudget, HorizontalPodAutoscaler, PodMonitor and other kinds, and no Pod and no ReplicaSet, which confirms the premise of the issue. (`k8s/bases/service-repos/appproject.yaml` is `services-admin`, the project of the `tenant-<name>` Applications.)
- `read_file charts/service-tenant/templates/appproject.yaml` lines 55 to 80 showed that the tenant AppProject writes its allow-list from the kinds of the entry at `charts/service-tenant/templates/appproject.yaml:64:namespaceResourceWhitelist:`, so that list decides which kinds the project permits.
- `read_file k8s/bases/service-repos/applicationsets.yaml` lines 125 to 165 showed `k8s/bases/service-repos/applicationsets.yaml:142:templatePatch: |`, the range over the images at `k8s/bases/service-repos/applicationsets.yaml:146:{{- range .images }}` and the per-alias strategy at `k8s/bases/service-repos/applicationsets.yaml:154:argocd-image-updater.argoproj.io/{{ .alias }}.update-strategy: digest`, so the force-update line goes into that same range.
- `read_file tests/test-service-repos.sh` lines 215 to 265 showed the image branch at `tests/test-service-repos.sh:233:if [ "$(yq '.images // [] | length' "$entry")" -gt 0 ]; then`, the update-strategy case at `tests/test-service-repos.sh:238:has the update strategy digest for each image`, the no-other-annotation case at `tests/test-service-repos.sh:242:has no other annotation` and its count at `tests/test-service-repos.sh:243:"$(yq '.images | length + 2' "$entry")"`, so the count becomes twice the image count plus 2.
- `read_file k8s/tests/service-repos/services/example.yaml` showed the two aliases at `k8s/tests/service-repos/services/example.yaml:14:- alias: web`, and `list_files k8s/tests/service-repos/services` listed `example.yaml` and `minimal.yaml`, so the only entry with images holds two aliases and the one-image case derives its entry with `yq` in the work folder.
- `read_file docs/service-repos.md` lines 88 to 118 showed the annotation table at `docs/service-repos.md:99:| Annotation | Value |` with the image-list, update-strategy and write-back-method rows and no force-update row, and the sentence at `docs/service-repos.md:97:entry with one or more images` that introduces that table.
- `search_code` for `test-service-repos.sh` answered `.github/workflows/ci.yml:298:run: mise exec -- tests/test-service-repos.sh` and `README.md:289:| K8s templates |`, and `read_file .github/workflows/ci.yml` lines 288 to 302 showed the job installs kustomize, yq, helm and kubeconform with `mise install --locked`, so the job runs the test that the first group changes.
- `references` for `force-update` answered `files 1, lines 1` with `scripts/k8s-validate.sh: 1 (line 140)`, and `read_file scripts/k8s-validate.sh` lines 136 to 143 showed `scripts/k8s-validate.sh:140:helm repo add "$dep_name" "$repo" --force-update >/dev/null 2>&1 || true`, the flag of `helm repo add` and no annotation of Image Updater, so that script stays as it is.
- `read_file k8s/bases/service-repos/imageupdater.yaml` showed the ImageUpdater object `service-repos` with `k8s/bases/service-repos/imageupdater.yaml:19:useAnnotations: true`, so the per-alias force-update annotation is the setting that Image Updater reads.
- `openspec/specs/` holds the capabilities `ci-check-names`, `pr-title-scopes` and `renovate-titles`, and none covers the service Applications, so `service-repos` is new; the repository root holds no `src` directory, so no behavior group and no Python test exists here.
- Each spec scenario names a live check with `kubectl` and no file of the repository: this repository holds no `src` directory for a behavior group, and the shell test is the check of group 1.
- The annotation set is counted by the case at `tests/test-service-repos.sh:242:has no other annotation`, whose expected length becomes twice the image count plus 2, which is 6 for the test entry with the aliases web and worker; the plan restricts the set to the four annotations of the images and removes nothing else.
- The plan calls no function whose arguments need a checkout of the repository, a client of a service or a network.
- The plan introduces no command and no verify program: `mise` is not in the runner tool list, `helm`, `kustomize` and `kubeconform` are `NOT_IN_RUNNER`, and `yq` is not listed, so the test runs on a workstation only; the live checks need a cluster and a person, and no step of the plan runs in the pod, needs a cluster token or reaches the network.
- The first checks against the real system are `mise install --locked` and `mise exec -- tests/test-service-repos.sh` on a workstation, the command of the job at `.github/workflows/ci.yml:298:run: mise exec -- tests/test-service-repos.sh`, and, after the infra release that holds this change, the bump of the `?ref=` of the consumer (`docs/service-repos.md:135`) and the Argo CD sync, `kubectl -n argocd logs deploy/argocd-image-updater-controller | grep 'imageUpdater_name=service-repos'` and `kubectl -n argocd get application -o yaml`.
- The live premise holds on 2026-11-27: the log of `argocd-image-updater-controller` reads `imageUpdater_name=service-repos ... applications=1 images_considered=0 images_skipped=1`, and the one service Application has `status.summary.images: null`.
- In `UpdateApplication` of Image Updater v1.5.0, `pkg/argocd/update.go:62` finds the force-update image among the live images (else it counts the image as skipped at lines 64 to 67), gives a nil tag a placeholder tag at lines 73 to 75, and counts it at line 77 (`NumImagesConsidered`). With the digest strategy, the update is needed on each cycle, and lines 231 to 234 skip the write when the new image is already set in the spec, so no write loop follows. The first cycle after the annotation lands writes the current digest, because `spec.source.kustomize` is empty, and this starts one rollout of the Deployments of the entry.
- `read_issue 163` answered closed (completed), and the patch block of that work is in the staged file at `k8s/bases/service-repos/applicationsets.yaml:158:{{- if hasKey . "patches" }}`, so no issue must be delivered first and the plan needs no dependency entry.
- The live controller is `quay.io/argoprojlabs/argocd-image-updater:v1.5.0` (`kubectl -n argocd get deploy argocd-image-updater-controller`). Its source at the tag v1.5.0 reads the per-alias key at `pkg/argocd/annotations.go:316` (`/%s.force-update`, alias) and, in `GetImagesFromApplication` at `pkg/argocd/argocd.go:1210`, adds each image with `ForceUpdate` to the live images when `app.Status.Summary.Images` does not hold it. So the annotation makes Image Updater consider an image that the Application status omits.
- The live service Application holds the annotation `notified.notifications.argoproj.io` of Argo CD Notifications next to the three annotations of Image Updater, so the live annotation count is not the count of the `templatePatch`; the spec counts only the annotations with the prefix `argocd-image-updater.argoproj.io/`, and the test counts the annotations of the rendered workload, which holds only those of the `templatePatch`.
- The issue can be built as written: option 1 adds no permission, and the allow-list of the tenant AppProject stays as it is.

## Existing Tool Considered

argoproj-labs/argocd-image-updater (Apache-2.0, maintained) already runs for `service-repos` at `k8s/bases/service-repos/imageupdater.yaml`; the change uses its per-alias force-update annotation and builds no code.

## Dependencies

None.
