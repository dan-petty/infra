## Purpose
The service-repos base renders the Applications of a services entry and the annotations that Argo CD Image Updater reads from them, so a new image digest reaches the service.

## ADDED Requirements

### Requirement: Force-update annotation for each image alias
The `templatePatch` of `service-workloads` SHALL write the annotation `argocd-image-updater.argoproj.io/<alias>.force-update` with the value `"true"` for each image alias of a services entry.

#### Scenario: Entry with image aliases
- **WHEN** after the infra release that holds this change, the bump of the `?ref=` of the consumer and the Argo CD sync, a person runs `kubectl -n argocd get application <name> -o yaml` for an entry with images
- **THEN** the annotations of the Application hold the key `argocd-image-updater.argoproj.io/<alias>.force-update` with the string value `"true"` for each alias of the entry

### Requirement: Only the annotations of the images
Of the annotations with the prefix `argocd-image-updater.argoproj.io/`, a service Application MUST hold only the `image-list`, `write-back-method`, `update-strategy` and `force-update` annotations of its images. An annotation that another controller writes, such as `notified.notifications.argoproj.io` of Argo CD Notifications, is not in this set.

#### Scenario: No other annotation of Image Updater
- **WHEN** after the sync a person runs `kubectl -n argocd get application <name> -o yaml` for an entry with N image aliases
- **THEN** the Application holds 2 x N + 2 annotations with the prefix `argocd-image-updater.argoproj.io/`: the image list, the write-back method, and one update-strategy and one force-update annotation for each alias

### Requirement: New digest of a pushed tag
A service Application MUST show the new digest of a pushed tag in `spec.source.kustomize.images`.

#### Scenario: Live proof of one image update
- **WHEN** after the sync a person records the digest in `spec.source.kustomize.images` of an entry with one image, pushes a new image to the tag that the entry names (for example `main`), and runs `kubectl -n argocd logs deploy/argocd-image-updater-controller | grep 'imageUpdater_name=service-repos' | grep images_considered` and `kubectl -n argocd get application <name> -o yaml`
- **THEN** the log shows `images_considered=1` and the Application holds the new digest, which differs from the recorded one, in `spec.source.kustomize.images`
