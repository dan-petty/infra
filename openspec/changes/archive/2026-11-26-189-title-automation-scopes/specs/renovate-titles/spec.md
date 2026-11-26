## Purpose
The titles that the shared Renovate preset `renovate/base.json` gives the update pull requests, so that they pass the title check.

## ADDED Requirements

### Requirement: The title of an image update names the image in short form
`renovate/base.json` SHALL name an image with a registry host by the last two parts of its reference in the title of an update, and SHALL leave the current tag out of the title of a digest update.

#### Scenario: A long image reference
- **WHEN** Renovate opens an update of `ghcr.io/dan-petty/devops-cli/service` to `v0.221.15`
- **THEN** the live check `Semantic PR title` passes with the title `chore(deps): update devops-cli/service Docker tag to v0.221.15`

#### Scenario: The preset stays valid
- **WHEN** `mise exec -- tests/test-renovate-presets.sh` runs
- **THEN** the config validator of Renovate accepts `renovate/base.json` in strict mode
