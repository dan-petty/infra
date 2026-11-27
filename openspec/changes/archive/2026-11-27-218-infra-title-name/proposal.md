# Proposal: name each pin of infra dan-petty/infra in the title

## Why
Each Renovate manager names this repository in its own form: `dan-petty/infra` (a reusable workflow), `github.com/dan-petty/infra` and `https://github.com/dan-petty/infra` (a remote, a module, a source), and `https://github.com/dan-petty/infra.git` (the copier template). The title of the update takes that name, and the title check allows at most 60 characters after the type (#218). dan-petty/dreamscaper#33, `chore: update https://github.com/dan-petty/infra.git to v0.24.3`, fails the check. `renovate/k8s.json` sets `overridePackageName` and the group `infra`, but a repository that extends only `renovate/base` does not read it.

## What Changes
- `renovate/base.json` gets a rule that gives each form of the name the topic `dan-petty/infra`, and a rule that gives the copier template the topic `dan-petty/infra template`. Both come after each other rule that sets a topic.
- `tests/test-renovate-presets.sh` checks that each form of the name gets such a topic.

## Capabilities
- `renovate-titles` (modified): one requirement for the name of infra in the title.

## Impact
- The titles of the pins of infra name `dan-petty/infra`. The branch names, the lookups, the groups and the copier branch of #216 do not change.
- The change fits one pull request.

## Feasibility
Confirmed on 2026-11-27 with Renovate 45.1.0 (the image of the Renovate CronJob), `--platform=local --dry-run=lookup`, on a repository that extends only `renovate/base` and holds `.copier-answers.yml` at v0.24.2: the copier update of `main` has the title `chore(deps): update https://github.com/dan-petty/infra.git to v0.24.3`; with the change it is `chore(deps): update dan-petty/infra template to v0.24.3`, on the same branch. The extract of `tests/renovate/` names infra as `dan-petty/infra`, `github.com/dan-petty/infra` and `https://github.com/dan-petty/infra.git`.

## Existing Tool Considered
Renovate covers the need with `commitMessageTopic`. `overridePackageName` would also shorten the title, but it changes the name that the copier and git lookups read.
