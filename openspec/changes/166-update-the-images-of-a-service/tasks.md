# Tasks

## 1. Write the force-update annotation and its test cases

Kind: other. Reads: `k8s/tests/service-repos/services/example.yaml`, `k8s/tests/service-repos/services/minimal.yaml`, `k8s/bases/service-repos/imageupdater.yaml`. Changes: `k8s/bases/service-repos/applicationsets.yaml`, `tests/test-service-repos.sh`.

- [ ] 1.1 First, in `tests/test-service-repos.sh`: add a case in the image branch that asserts the force-update annotation of each alias with the string value `"true"` (an unquoted boolean must fail the case), change the expected count of the no-other-annotation case to the yq expression `.images | (length * 2) + 2` (yq reads `length * 2 + 2` as `length * (2 + 2)`), and add a case after the loop that derives a one-image entry with `yq '.images |= .[:1]'` in the work folder and asserts its single force-update annotation. Then, in `k8s/bases/service-repos/applicationsets.yaml`, add the line `argocd-image-updater.argoproj.io/{{ .alias }}.force-update: "true"` inside the range over `.images` of the `templatePatch`, after the update-strategy line, and name the new annotation in the comment above the patch, and run this check by hand: On a workstation with the mise tools installed, run `mise install --locked`, then `mise exec -- tests/test-service-repos.sh`: every case passes, including the force-update case of each alias, the one-image case and the annotation count. The job `K8s templates` of `.github/workflows/ci.yml` runs the same command.

## 2. Document the force-update annotation

Kind: other. Reads: `k8s/bases/service-repos/applicationsets.yaml`, `tests/test-service-repos.sh`. Changes: `docs/service-repos.md`.

- [ ] 2.1 Add a row for `argocd-image-updater.argoproj.io/<alias>.force-update` with the value `true` to the annotation table of `docs/service-repos.md`, and one sentence on why the annotation is needed: the AppProject permits no Pod and no ReplicaSet, so the Application status holds no image, and Image Updater considers an image only with this annotation, and run this check by hand: Read the annotation table of `docs/service-repos.md` and compare it with the annotation lines of `k8s/bases/service-repos/applicationsets.yaml`: the table names each of the four annotations, and the force-update row says that Image Updater considers an image that the Application status omits.

## Criteria

- Pending person: The log of `service-repos` shows `images_considered=1` for an entry with 1 image., Only the live ImageUpdater of the cluster writes this log line, and the implementation pod has no cluster token.
- Pending person: After a new push of the tag, the Application has the new digest in `spec.source.kustomize.images`., The digest appears only after a real push reaches the registry of the cluster and Image Updater writes it back, and no offline test reaches the cluster.
