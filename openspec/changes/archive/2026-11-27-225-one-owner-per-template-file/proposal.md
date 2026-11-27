# Proposal: give each template file one owner for copier updates

## Why
Each copier update of infra fails with merge conflicts, so `renovate/artifacts` fails and no update merges (#225): dan-petty/dotfiles#22, dan-petty/devcontainer-features#30 and dan-petty/dreamscaper#33 conflict in `.github/labels.yml` and `.github/workflows/pr-title.yml`, and #224 also in `.github/workflows/release.yml`. The cause is two owners of one file. The github-actions manager of Renovate moves the pin of each caller that the template renders, and `copier update` renders the same caller at another release. The repositories also changed template files by hand, and `copier update` merges the template into files whose content belongs to the repository, such as `.github/renovate.json` and `version.txt`. Renovate also splits the copier update into a patch branch and a minor branch that change the same files. infra renders its own template, so #224 conflicts on infra's own files.

Owner, 2026-11-27: "standardize templates and workflows where possible" and "don't build custom solutions where standard conventions already cover the use cases".

## What Changes
- `copier.yml` gets `_skip_if_exists` for the files whose content belongs to the repository after the first copy: `.github/renovate.json`, `.pre-commit-config.yaml`, `.devops/project.toml`, `version.txt` and `.release-please-manifest.json`. The template owns each other file.
- `copier.yml` gets the answer `scope_descriptions` (a YAML mapping, default `{}`): the description of each `scope/<scope>` label. The consumers hold their own descriptions, which the template renders in place of "The area <scope> of this repository".
- `copier.yml` gets the answer `required_checks`, default empty. The ruleset `main` of `github/repository.yaml` requires each check of the answer and the title check `PR title / Semantic PR title`, from GitHub Actions (integration 15368). dan-petty/homelab answers `K8s,Lint` in place of a change of the file.
- `renovate/base.json` turns off the github-actions manager for the pin of `dan-petty/infra` in `.github/workflows/pr-title.yml` and `.github/workflows/release.yml`, the callers that the template renders, and gives the copier manager one branch with `separateMajorMinor: false` and `separateMinorPatch: false`.
- infra's own `.copier-answers.yml` goes: infra is the template source, not a render of it. Then #224 has no cause.
- The template files that hold answers name the answer to change. `tests/test-repository-template.sh` and `tests/test-renovate-presets.sh` get the cases of the new behavior. README.md, `renovate/README.md` and `templates/README.md` describe the owners.

## Capabilities
- `template-file-owners` (new): the owner of each file of the repository template, and the scope descriptions and the required checks as answers.
- `renovate-copier` (modified by ADDED requirements): the copier update has one branch, and Renovate leaves the template callers to it.
- `template-workflow-pins` (REMOVED requirement): Renovate and `copier update` no longer both write the caller.

## Impact
- Each consumer re-adopts the template once with `copier recopy --skip-answered --defaults --overwrite --vcs-ref <release>` and its answers, in one pull request of its own, after the release that holds this change. The next copier update of each consumer then merges with its checks.
- A repository that changes a template file by hand loses the change at the next copier update: it changes the template or an answer.
- Renovate opens no pull request for the pins of the template callers. The pins of infra in other files, such as a caller of `k8s-validate.yml`, keep their updates in the group `infra`.
- The change fits one pull request.

## Feasibility
Confirmed on 2026-11-27:
- Copier 9.19.1 (`uv sync --frozen`): over a render of a tag with its own content in the five files, `copier update --skip-answered --defaults` and `copier recopy --skip-answered --defaults --overwrite` to the next tag keep each file of `_skip_if_exists` and give each other file the render of the next tag. With the copier.yml of `main`, `copier update` writes conflict markers into `version.txt` and `.release-please-manifest.json`, and `copier recopy` writes over the five files (`tests/test-repository-template.sh`, 7 new cases fail on `main`).
- Renovate 45.1.0 `--platform=local --dry-run=lookup` of the fixture with `.copier-answers.yml` at `v0.24.1`: with the presets of `main`, the copier dependency gets two updates, `v0.24.3` in `renovate/https-github.com-dan-petty-infra.git-0.24.x` and `v0.25.2` in `renovate/https-github.com-dan-petty-infra.git-0.x`; with the change, one update to `v0.25.2` in the bucket `latest`, branch `renovate/https-github.com-dan-petty-infra.git-0.x`. The source of Renovate 45.1.0 (`workers/repository/process/fetch.js`) applies the package rules before the lookup and gives a dependency with `enabled: false` the skip reason `disabled`.
- A recopy of each consumer with only `scopes` replaced 60 descriptions of its own scope labels, in 5 of 6 consumers, with "The area <scope> of this repository". With `scope_descriptions`, each description stays.
- The live ruleset `main` of dan-petty/homelab requires `K8s`, `Lint` and `PR title / Semantic PR title` from integration 15368, the checks of its `github/repository.yaml`.

## Existing Tool Considered
Copier `_skip_if_exists`, a `type: yaml` question and `copier recopy`, and the Renovate options `matchFileNames`, `enabled`, `separateMajorMinor` and `separateMinorPatch`, all documented options of the tools in use. No script is added. The change deletes infra's `.copier-answers.yml` and the test case that moved the callers as Renovate did before `copier update`.
