## ADDED Requirements

### Requirement: The title of an infra pin names dan-petty/infra
`renovate/base.json` SHALL give the topic `dan-petty/infra` to each form of the name of this repository (`dan-petty/infra`, `github.com/dan-petty/infra`, `https://github.com/dan-petty/infra`, `https://github.com/dan-petty/infra.git`), and the topic `dan-petty/infra template` to the copier template.

#### Scenario: Each form of the name
- **WHEN** `mise exec -- tests/test-renovate-presets.sh` runs
- **THEN** the case of the infra name passes: each form matches a rule with a topic that starts with `dan-petty/infra`, after each other rule that sets a topic

#### Scenario: The copier update
- **WHEN** Renovate 45.1.0 runs `--platform=local --dry-run=lookup` on a repository that extends only `renovate/base` and holds `.copier-answers.yml` of this repository at an older release
- **THEN** the title of the update is `chore(deps): update dan-petty/infra template to <version>`
