# Design

## Decisions
- **`commitMessageTopic`, not `overridePackageName`.** The topic changes only the text of the title. The lookups of the copier and git managers keep the URL.
- **A rule for each form at the end of `packageRules`.** A later rule overrides an earlier one, so the topic of infra wins over the topic of the actions rule.
- **Its own topic for the copier template.** One release of infra gives a copier update and an update of the other pins in two branches (#216). Different titles keep the two pull requests apart.

## Rejected alternatives
- **Skip the title check for the Renovate App.** The title is the squash commit subject that release-please reads, so a long title still reaches `main`.
- **The group `infra` of `renovate/k8s.json` in `renovate/base.json`.** It puts the copier update into the branch of the other pins, where `copier update` stops (#216).
