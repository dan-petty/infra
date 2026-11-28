## REMOVED Requirements

### Requirement: The title check accepts the scopes of the shared automation in every repository
**Reason**: `scripts/pr-title-scopes.sh` moved to dan-petty/github-workflows with the reusable workflow `pr-title.yml` (#217).
**Migration**: The spec `pr-title-scopes` of dan-petty/github-workflows holds the requirement.

### Requirement: The title check needs a labels file with a list
**Reason**: `scripts/pr-title-scopes.sh` moved to dan-petty/github-workflows with the reusable workflow `pr-title.yml` (#217).
**Migration**: The spec `pr-title-scopes` of dan-petty/github-workflows holds the requirement.

## MODIFIED Requirements

### Requirement: infra declares the scopes of its own titles
`.github/labels.yml` of infra SHALL declare a `scope/<name>` label for each scope that a pull request title of infra can have and that is not a scope of every repository. The title check of infra, `pr-title.yml` of dan-petty/github-workflows, reads these labels.

#### Scenario: The scopes of the issue titles
- **WHEN** `scripts/pr-title-scopes.sh .github/labels.yml` of dan-petty/github-workflows, at the tag of the pin of `pr-title-caller.yml`, runs in infra
- **THEN** the output holds `security`, `terraform`, `templates` and `tools`
