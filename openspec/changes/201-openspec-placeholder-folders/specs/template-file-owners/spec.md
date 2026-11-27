## ADDED Requirements

### Requirement: The template renders the folders of OpenSpec
The template SHALL render an empty `openspec/specs/.gitkeep` and an empty `openspec/changes/archive/.gitkeep` next to `openspec/config.yaml`, the layout that `openspec init` writes, so that a repository holds `openspec/specs/` before its first archived spec.

#### Scenario: Each render holds the two empty files
- **WHEN** Copier renders the working tree with each answer set of the test
- **THEN** `mise exec -- tests/test-repository-template.sh` finds `openspec/specs/.gitkeep` and `openspec/changes/archive/.gitkeep` in the exact file list of each render, each with 0 bytes
