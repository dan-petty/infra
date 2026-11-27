## MODIFIED Requirements

### Requirement: The copier update has its own branch
The shared Renovate presets SHALL NOT put a copier update into the group `infra` or into another group with other pins.

#### Scenario: The preset leaves the copier manager out
- **WHEN** `mise exec -- tests/test-renovate-presets.sh` runs
- **THEN** the case of the group infra passes: each rule that sets the group `infra` has `!copier` in `matchManagers`

#### Scenario: The lookup gives the copier update its own branch
- **WHEN** Renovate 45.1.0 runs `--platform=local --dry-run=lookup` on the fixture `tests/renovate/`, which extends `renovate/base` and `renovate/k8s` and holds `.copier-answers.yml` of dan-petty/github-workflows
- **THEN** each update of the copier dependency has a branch name that starts with `renovate/https-github.com-dan-petty-github-workflows`, with no group

### Requirement: Renovate leaves the template callers to the copier update
The shared Renovate presets SHALL turn off the github-actions manager for the pin of `dan-petty/github-workflows` in each caller that its repository template renders (`.github/workflows/pr-title.yml` and `.github/workflows/release.yml`). A pin of dan-petty/github-workflows in another workflow SHALL keep its updates.

#### Scenario: The preset names each caller of the template
- **WHEN** `mise exec -- tests/test-renovate-presets.sh` runs
- **THEN** the case passes that a rule of `renovate/base.json` with `enabled: false` matches the manager github-actions, the package `dan-petty/github-workflows`, `.github/workflows/pr-title.yml` and `.github/workflows/release.yml`

#### Scenario: The lookup skips the caller of the template
- **WHEN** Renovate 45.1.0 runs `--platform=local --dry-run=lookup` with a GitHub token on the fixture `tests/renovate/`
- **THEN** the pin of dan-petty/github-workflows in `.github/workflows/pr-title.yml` has the skip reason `disabled`, and the pin in `.github/workflows/k8s.yml` gets the repository `https://github.com/dan-petty/github-workflows` with no warning

### Requirement: The copier update has one branch with the newest release
The shared Renovate presets SHALL give the copier manager `separateMajorMinor: false` and `separateMinorPatch: false`, so that each repository gets at most one copier update, to the newest release of the template.

#### Scenario: The preset joins the update types of the copier update
- **WHEN** `mise exec -- tests/test-renovate-presets.sh` runs
- **THEN** the case passes that a rule of `renovate/base.json` for the manager copier sets `separateMajorMinor` and `separateMinorPatch` to false

#### Scenario: The lookup gives one update
- **WHEN** Renovate 45.1.0 runs `--platform=local --dry-run=lookup` on the fixture `tests/renovate/`, whose `.copier-answers.yml` names `https://github.com/dan-petty/github-workflows.git` at `v0.1.0`
- **THEN** the copier dependency gets the repository `https://github.com/dan-petty/github-workflows` with no warning and at most one update

## ADDED Requirements

### Requirement: Renovate leaves the workflows and the template of infra alone
The shared Renovate presets SHALL turn off the github-actions manager and the copier manager for each form of the name of dan-petty/infra, in each file: a release of infra holds no reusable workflow and no repository template (#217).

#### Scenario: The preset turns off both managers for infra
- **WHEN** `mise exec -- tests/test-renovate-presets.sh` runs
- **THEN** the case passes that a rule of `renovate/base.json` with `enabled: false`, the managers github-actions and copier and no file condition matches `dan-petty/infra` and `https://github.com/dan-petty/infra.git`

#### Scenario: The lookup skips each pin of a workflow or the template of infra
- **WHEN** Renovate 45.1.0 runs `--platform=local --dry-run=lookup` with a GitHub token on the fixture `tests/renovate/`
- **THEN** the pin of infra in `.github/workflows/k8s-infra.yml` and the pin of infra in `.copier-answers.infra.yml` have the skip reason `disabled`, and the Kustomize, OpenTofu, Ansible and Argo CD pins of infra get the repository `https://github.com/dan-petty/infra` with no warning
