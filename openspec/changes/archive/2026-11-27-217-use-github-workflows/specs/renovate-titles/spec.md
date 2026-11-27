## MODIFIED Requirements

### Requirement: The title of an infra pin names dan-petty/infra
`renovate/base.json` SHALL give the topic `dan-petty/infra` to each form of the name of this repository (`dan-petty/infra`, `github.com/dan-petty/infra`, `https://github.com/dan-petty/infra`, `https://github.com/dan-petty/infra.git`).

#### Scenario: Each form of the name
- **WHEN** `mise exec -- tests/test-renovate-presets.sh` runs
- **THEN** the case of the infra name passes: for each form, the last rule that sets a topic and can match the form has a topic that starts with `dan-petty/infra`

#### Scenario: The copier update
- **WHEN** Renovate 45.1.0 runs `--platform=local --dry-run=lookup` with a GitHub token on the fixture `tests/renovate/`
- **THEN** the copier render of infra in `.copier-answers.infra.yml` has the skip reason `disabled`, so Renovate opens no copier update of infra and gives it no title

## ADDED Requirements

### Requirement: The title of a pin of dan-petty/github-workflows names the repository
`renovate/base.json` SHALL give the topic `dan-petty/github-workflows` to each form of the name of dan-petty/github-workflows (`dan-petty/github-workflows`, `github.com/dan-petty/github-workflows`, `https://github.com/dan-petty/github-workflows`, `https://github.com/dan-petty/github-workflows.git`), and the topic `dan-petty/github-workflows template` to its copier template.

#### Scenario: Each form of the name
- **WHEN** `mise exec -- tests/test-renovate-presets.sh` runs
- **THEN** the case of the name dan-petty/github-workflows passes: for each form, the last rule that sets a topic and can match the form has a topic that starts with `dan-petty/github-workflows`

#### Scenario: The copier update
- **WHEN** `mise exec -- tests/test-renovate-presets.sh` runs
- **THEN** the case passes that the last rule that sets a topic and can match the copier update of `https://github.com/dan-petty/github-workflows.git` gives the topic `dan-petty/github-workflows template`
