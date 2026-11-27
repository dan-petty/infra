## ADDED Requirements

### Requirement: Renovate leaves the template callers to the copier update
The shared Renovate presets SHALL turn off the github-actions manager for the pin of `dan-petty/infra` in each caller that the repository template renders (`.github/workflows/pr-title.yml` and `.github/workflows/release.yml`). A pin of infra in another workflow SHALL keep its updates.

#### Scenario: The preset names each caller of the template
- **WHEN** `mise exec -- tests/test-renovate-presets.sh` runs
- **THEN** the case passes that a rule of `renovate/base.json` with `enabled: false` matches the manager github-actions, the package `dan-petty/infra` and each caller of `templates/repository/.github/workflows/`

#### Scenario: The lookup skips the caller of the template
- **WHEN** Renovate 45.1.0 runs `--platform=local --dry-run=lookup` with a GitHub token on the fixture `tests/renovate/`
- **THEN** the pin of infra in `.github/workflows/pr-title.yml` has the skip reason `disabled`, and the pin of infra in `.github/workflows/k8s.yml` gets the repository `https://github.com/dan-petty/infra` with no warning

### Requirement: The copier update has one branch with the newest release
The shared Renovate presets SHALL give the copier manager `separateMajorMinor: false` and `separateMinorPatch: false`, so that each repository gets one copier update, to the newest release of the template.

#### Scenario: The preset joins the update types of the copier update
- **WHEN** `mise exec -- tests/test-renovate-presets.sh` runs
- **THEN** the case passes that a rule of `renovate/base.json` for the manager copier sets `separateMajorMinor` and `separateMinorPatch` to false

#### Scenario: The lookup gives one update
- **WHEN** Renovate 45.1.0 runs `--platform=local --dry-run=lookup` on the fixture `tests/renovate/`, whose `.copier-answers.yml` is at `v0.24.1`
- **THEN** the copier dependency has one update, in the bucket `latest`
