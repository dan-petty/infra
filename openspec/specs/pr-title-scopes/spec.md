# pr-title-scopes Specification

## Purpose

The scopes that the pull request title check of the reusable workflow `pr-title.yml` of dan-petty/github-workflows accepts in infra.

## Requirements

### Requirement: infra declares the scopes of its own titles
`.github/labels.yml` of infra SHALL declare a `scope/<name>` label for each scope that a pull request title of infra can have and that is not a scope of every repository. The title check of infra, `pr-title.yml` of dan-petty/github-workflows, reads these labels.

#### Scenario: The scopes of the issue titles
- **WHEN** `scripts/pr-title-scopes.sh .github/labels.yml` of dan-petty/github-workflows, at the tag of the pin of `pr-title-caller.yml`, runs in infra
- **THEN** the output holds `security`, `terraform`, `templates` and `tools`
