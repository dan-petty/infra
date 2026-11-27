# Tasks

## 1. Behavior

- [x] 1.1 Add the case to `tests/test-renovate-presets.sh` that each form of the infra name gets a topic that starts with `dan-petty/infra`, and see it fail on `main`
  - Verification: `$ mise exec -- tests/test-renovate-presets.sh`
- [x] 1.2 Add the two rules to `renovate/base.json`
  - Verification: `$ mise exec -- tests/test-renovate-presets.sh`
- [x] 1.3 Check the title of the copier update with a Renovate lookup on a repository that extends only `renovate/base`, as in `## Feasibility` of the proposal
  - Verification: `$ renovate --platform=local --dry-run=lookup` of Renovate 45.1.0 gives `chore(deps): update dan-petty/infra template to v0.24.3`
