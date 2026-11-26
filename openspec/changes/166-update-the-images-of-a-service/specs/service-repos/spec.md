## Purpose
The service-repos base renders the Applications of a services entry and the annotations that Argo CD Image Updater reads from them, so a new image digest reaches the service.

## ADDED Requirements

### Requirement: Force-update annotation for each image alias
The `templatePatch` of `service-workloads` SHALL write the annotation `argocd-image-updater.argoproj.io/<alias>.force-update` with the value `"true"` for each image alias of a services entry.

#### Scenario: Entry with one image alias
- **WHEN** a person syncs an entry with one image alias and runs `kubectl -n argocd get application <name> -o yaml`
- **THEN** the annotations of the Application hold the key `argocd-image-updater.argoproj.io/web.force-update` with the value `"true"`

#### Scenario: Entry with two image aliases
- **WHEN** a person syncs an entry with the aliases `web` and `worker` and runs `kubectl -n argocd get application <name> -o yaml`
- **THEN** the annotations of the Application hold one force-update key for each of the two aliases, and each value is `"true"`

### Requirement: Only the annotations of the images
A service Application MUST hold only the `image-list`, `write-back-method`, `update-strategy` and `force-update` annotations of its images.

#### Scenario: No other annotation on an entry with two images
- **WHEN** a person syncs an entry with two images and runs `kubectl -n argocd get application <name> -o yaml`
- **THEN** the Application holds 6 annotations: the image list, the write-back method, and one update-strategy and one force-update annotation for each of the two images

### Requirement: New digest of a pushed tag
A service Application MUST show the new digest of a pushed tag in `spec.source.kustomize.images`.

#### Scenario: Live proof of one image update
- **WHEN** after the merge a person pushes a new tag of an entry with one image and runs `kubectl -n argocd logs deploy/argocd-image-updater` and `kubectl -n argocd get application <name> -o yaml`
- **THEN** the log shows `images_considered=1` and the Application holds the new digest in `spec.source.kustomize.images`
