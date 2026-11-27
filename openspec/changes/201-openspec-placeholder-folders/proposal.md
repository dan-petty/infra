# Proposal: the template keeps the OpenSpec folders

## Why
The repository template renders `openspec/config.yaml`, but no `openspec/specs/` and no `openspec/changes/archive/` (#201). Git keeps no empty folder, so a repository has no `openspec/specs/` until its first change archives a spec. The OpenSpec row of `devops repos onboard` reads `openspec/specs/` on the default branch, so it reports `invalid` for each such repository: dan-petty/devtools after its re-adoption of v0.25.3 on 2026-11-27. Its message says that the next copier update adds the folder, but no release of the template holds it.

## What Changes
- The template gets the two empty files that `openspec init` writes: `templates/repository/openspec/specs/.gitkeep` and `templates/repository/openspec/changes/archive/.gitkeep`.
- `tests/test-repository-template.sh` expects both files in the render of each answer set, empty.
- `templates/README.md` names the two files and the new test case.

## Capabilities
- `template-file-owners` (modified by an ADDED requirement): the template renders the folders of OpenSpec.

## Impact
- The next copier update of each consumer adds the two files. A repository that already has the folders gets only the empty `.gitkeep` files. OpenSpec reads a spec from a folder with a `spec.md`, so the files are no spec.
- The change fits one pull request.

## Feasibility
Confirmed on 2026-11-27:
- `openspec init` of OpenSpec 2.2.0 writes `openspec/specs/.gitkeep` and `openspec/changes/archive/.gitkeep` (issue #201).
- The template of `v0.25.3` and of `main` holds only `openspec/config.yaml` below `openspec/` (`git/trees` of dan-petty/infra), and dan-petty/devtools holds `openspec/config.yaml` and `openspec/changes/` and no `openspec/specs/`.
- `devops repos onboard dan-petty/devtools --plan` (devops-cli 0.228.2) gives row 16 `invalid` with "openspec/specs/ is absent".
- `copier.yml` excludes only release files (`_exclude`), so Copier renders a `.gitkeep` file. The new cases of `tests/test-repository-template.sh` fail on `main` (12 of 137) and pass with the two files (137 of 137), also in the update and recopy cases.

## Existing Tool Considered
`openspec init` (Fission-AI/OpenSpec, MIT) writes the same layout, but it asks questions and writes the files of tool skills. A Copier render runs with no person, so the template ships the two placeholder files of `openspec init` as static files. No script is added.
