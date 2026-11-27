## Purpose

The copier update of the repository template that each consumer of infra receives from Renovate, so that `copier update` runs on a clean branch.

## ADDED Requirements

### Requirement: The copier update has its own branch
The shared Renovate presets SHALL NOT put the copier update of `https://github.com/dan-petty/infra.git` into the group `infra` or into another group with the other pins of infra.

#### Scenario: The preset leaves the copier manager out
- **WHEN** `mise exec -- tests/test-renovate-presets.sh` runs
- **THEN** the case of the group infra passes: each rule that sets the group `infra` has `!copier` in `matchManagers`

#### Scenario: The lookup gives the copier update its own branch
- **WHEN** Renovate 45.1.0 runs `--platform=local --dry-run=lookup` on a repository that extends `renovate/base` and `renovate/k8s` and holds `.copier-answers.yml` of infra at an older release
- **THEN** the copier update has a branch of its own, with no group
