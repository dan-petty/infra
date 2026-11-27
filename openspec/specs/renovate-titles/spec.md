# renovate-titles Specification

## Purpose

The titles that the shared Renovate preset `renovate/base.json` gives the update pull requests, so that they pass the title check.

## Requirements

### Requirement: The title of an image update names the image in short form
`renovate/base.json` SHALL name an image with a registry host by the last two parts of its reference in the title of an update, and SHALL leave the current tag out of the title of a digest update.

#### Scenario: A long image reference
- **WHEN** Renovate opens an update of `ghcr.io/dan-petty/devops-cli/service` to `v0.221.15`
- **THEN** the live check `Semantic PR title` passes with the title `chore(deps): update devops-cli/service Docker tag to v0.221.15`

#### Scenario: The preset stays valid
- **WHEN** `mise exec -- tests/test-renovate-presets.sh` runs
- **THEN** the config validator of Renovate accepts `renovate/base.json` in strict mode

### Requirement: The title of an infra pin names dan-petty/infra
`renovate/base.json` SHALL give the topic `dan-petty/infra` to each form of the name of this repository (`dan-petty/infra`, `github.com/dan-petty/infra`, `https://github.com/dan-petty/infra`, `https://github.com/dan-petty/infra.git`).

#### Scenario: Each form of the name
- **WHEN** `mise exec -- tests/test-renovate-presets.sh` runs
- **THEN** the case of the infra name passes: for each form, the last rule that sets a topic and can match the form has a topic that starts with `dan-petty/infra`

#### Scenario: The copier update
- **WHEN** Renovate 45.1.0 runs `--platform=local --dry-run=lookup` with a GitHub token on the fixture `tests/renovate/`
- **THEN** the copier render of infra in `.copier-answers.infra.yml` has the skip reason `disabled`, so Renovate opens no copier update of infra and gives it no title

### Requirement: The title of a pin of dan-petty/github-workflows names the repository
`renovate/base.json` SHALL give the topic `dan-petty/github-workflows` to each form of the name of dan-petty/github-workflows (`dan-petty/github-workflows`, `github.com/dan-petty/github-workflows`, `https://github.com/dan-petty/github-workflows`, `https://github.com/dan-petty/github-workflows.git`), and the topic `dan-petty/github-workflows template` to its copier template.

#### Scenario: Each form of the name
- **WHEN** `mise exec -- tests/test-renovate-presets.sh` runs
- **THEN** the case of the name dan-petty/github-workflows passes: for each form, the last rule that sets a topic and can match the form has a topic that starts with `dan-petty/github-workflows`

#### Scenario: The copier update
- **WHEN** `mise exec -- tests/test-renovate-presets.sh` runs
- **THEN** the case passes that the last rule that sets a topic and can match the copier update of `https://github.com/dan-petty/github-workflows.git` gives the topic `dan-petty/github-workflows template`
