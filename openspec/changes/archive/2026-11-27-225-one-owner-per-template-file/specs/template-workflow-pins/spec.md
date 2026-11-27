## REMOVED Requirements

### Requirement: Renovate and copier update write the same caller
**Reason**: Two owners of one caller conflict when Renovate and `copier update` move it to different releases (#225). Renovate now leaves the callers of the template to the copier update.
**Migration**: The requirements "Each file of the template has one owner" of `template-file-owners` and "Renovate leaves the template callers to the copier update" of `renovate-copier` replace it.
