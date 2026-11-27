# Proposal: give the copier update of infra its own Renovate branch

## Why
`renovate/k8s.json` puts each pin of dan-petty/infra into the group `infra` (#216). Its pattern also matches the copier source `https://github.com/dan-petty/infra.git` of `.copier-answers.yml`, so in a repository that extends `renovate/k8s` the copier update shares a branch with the other pins. The other managers change files of that branch first, and `copier update` then stops ("Destination repository is dirty"). dan-petty/homelab#392 and dan-petty/danielpetty.com#105 merged with no template update, and both repositories stay at template v0.24.1.

## What Changes
- The rule of the group `infra` in `renovate/k8s.json` sets `matchManagers: ["!copier"]`, so the copier update gets its own branch.
- `tests/test-renovate-presets.sh` checks that each rule of the group `infra` leaves the copier manager out.

## Capabilities
- `renovate-copier` (new): the copier update of the repository template.

## Impact
- In a repository that extends `renovate/k8s`, one release of infra gives two pull requests: the pins of infra, and the copier update. The copier update runs `copier update` on a clean branch.
- The next copier pull request in dan-petty/homelab and dan-petty/danielpetty.com is the catch-up from v0.24.1.
- The change fits one pull request.

## Feasibility
Confirmed on 2026-11-27 with Renovate 45.1.0 (the image of the Renovate CronJob), `--platform=local --dry-run=lookup`, on a repository that extends `renovate/base` and `renovate/k8s` and holds `.copier-answers.yml` at v0.24.2: with the presets of `main`, the copier update has the branch `renovate/patch-infra` in the group `infra`; with the change it has the branch `renovate/https-github.com-dan-petty-infra.git-0.24.x` and no group. `renovate-config-validator --strict` accepts the negated manager.

## Existing Tool Considered
Renovate `packageRules` with a negated `matchManagers` and the copier manager of Renovate, both in use. No tool or script is added.
