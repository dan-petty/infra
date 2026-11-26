# pr-title-scopes Specification

## Purpose

The scopes that the pull request title check of the reusable workflow `pr-title.yml` accepts in a repository that calls it.

## Requirements

### Requirement: The title check accepts the scopes of the shared automation in every repository
`scripts/pr-title-scopes.sh` SHALL print `ci`, `deps`, `docs`, `main` and `spec`, and the name after `scope/` of each `scope/*` label of the labels file of the caller, each one time and one on each line.

#### Scenario: A repository with no scope label
- **WHEN** the labels file holds no `scope/*` label
- **THEN** the script prints `ci`, `deps`, `docs`, `main` and `spec`

#### Scenario: A repository with its own scope labels
- **WHEN** the labels file holds the labels `scope/k8s` and `scope/ci`
- **THEN** the script prints `k8s`, `ci`, `deps`, `docs`, `main` and `spec`, each one time

### Requirement: The title check needs a labels file with a list
`scripts/pr-title-scopes.sh` SHALL exit non-zero, print no scope and name the labels file on standard error when the file does not exist or holds no list.

#### Scenario: No labels file
- **WHEN** the labels file does not exist
- **THEN** the script exits 1 and names the file

#### Scenario: A file with no list
- **WHEN** the labels file holds a mapping
- **THEN** the script exits 1 and names the file

### Requirement: infra declares the scopes of its own titles
`.github/labels.yml` of infra SHALL declare a `scope/<name>` label for each scope that a pull request title of infra can have and that is not a scope of every repository.

#### Scenario: The scopes of the issue titles
- **WHEN** `scripts/pr-title-scopes.sh .github/labels.yml` runs in infra
- **THEN** the output holds `security`, `terraform`, `templates` and `tools`
