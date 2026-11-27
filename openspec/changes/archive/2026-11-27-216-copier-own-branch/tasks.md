# Tasks

## 1. Behavior

- [x] 1.1 Add the case to `tests/test-renovate-presets.sh` that each rule of the group `infra` leaves the copier manager out, and see it fail on `main`
  - Verification: `$ mise exec -- tests/test-renovate-presets.sh`
- [x] 1.2 Set `matchManagers: ["!copier"]` on the group rule of `renovate/k8s.json`
  - Verification: `$ mise exec -- tests/test-renovate-presets.sh`
- [x] 1.3 Check the branch of the copier update with a Renovate lookup, as in `## Feasibility` of the proposal
  - Verification: `$ renovate --platform=local --dry-run=lookup` of Renovate 45.1.0 gives the copier update the branch `renovate/https-github.com-dan-petty-infra.git-0.24.x`

## Workflow follow-up

- After the release that holds this change, check that the copier pull requests of dan-petty/homelab and dan-petty/danielpetty.com run `copier update` with no artifact error and move `_commit` from v0.24.1.
