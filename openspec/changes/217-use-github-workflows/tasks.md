# Tasks

## 1. The Renovate rules of the move

Kind: behavior.

- [x] 1.1 Change the fixture `tests/renovate/` and `tests/test-renovate-presets.sh`: the callers and the template render of dan-petty/github-workflows, a caller and a template render of infra, the title cases of both names, the case of the template callers, the case of the infra rule, and their lookup cases. See the offline cases fail on `main`
  - Verification: `$ mise exec -- tests/test-renovate-presets.sh`
- [x] 1.2 Change the title rules and the rule of #225 in `renovate/base.json`, add the rule that turns off the github-actions manager and the copier manager for infra, and correct the description of the group `infra` in `renovate/k8s.json`
  - Verification: `$ mise exec -- tests/test-renovate-presets.sh`
- [x] 1.3 Run the lookup of the fixture with a GitHub token, as in `## Feasibility` of the proposal
  - Verification: `RENOVATE_GITHUB_COM_TOKEN=<token> CI=true mise exec -- tests/test-renovate-presets.sh` passes each lookup case

## 2. The callers of infra

Kind: other.

- [x] 2.1 Point `ci.yml`, `pr-title-caller.yml` and `release-caller.yml` at dan-petty/github-workflows `v0.1.0`; remove the jobs `kube-linter config` and `Repository template`, the filter `template` and the steps and filter entries of the deleted files
  - Verification: `mise exec -- actionlint`, `.venv/bin/zizmor --offline .github/workflows/` and `mise exec -- tests/test-ci-check-names.sh` exit 0
- [x] 2.2 Run kubeconform in `tests/test-service-repos.sh` in place of the deleted script
  - Verification: `mise exec -- tests/test-service-repos.sh` exits 0
- [x] 2.3 Run the script of dan-petty/github-workflows `v0.1.0` with the inputs of the job `k8s-validate`
  - Verification: the K8s command of README.md, "Checks" exits 0

## 3. Deletions

Kind: other.

- [x] 3.1 Delete the moved workflows, scripts, tests, `.kube-linter.yaml`, `copier.yml`, `templates/`, `.github/zizmor.yml`, the actionlint entries, and Copier and check-jsonschema of `pyproject.toml`, then run `uv lock`
  - Verification: `git ls-files copier.yml templates scripts/pr-title-scopes.sh scripts/k8s-validate.sh .kube-linter.yaml` prints nothing, and `rg -n '^  workflow_call:' .github/workflows` prints nothing
- [x] 3.2 Delete the specs `template-file-owners`, `template-workflow-pins` and `reusable-workflow-runner`
  - Verification: `git ls-files openspec/specs` lists none of them

## 4. Documents

Kind: other.

- [x] 4.1 Correct README.md ("Layout", "Pin a release", "Releases", "Call the reusable workflows", "Tools", "Checks"), `renovate/README.md`, `helm/README.md`, `k8s/tests/README.md`, the label `scope/templates` and each comment that names a deleted file
  - Verification: `rg -n 'dan-petty/infra/\.github/workflows|dan-petty/infra\.git' README.md docs .github openspec/specs` prints only the forms of infra that a consumer still pins, `.venv/bin/yamllint --strict .` and `mise exec -- scripts/private-data-scan.sh dir .` exit 0

## Workflow follow-up

- Before the merge, a person removes the required checks `Repository template` and `kube-linter config` from the ruleset `main` of infra.
- After the merge, each consumer moves to dan-petty/github-workflows once (`renovate/README.md`, "Move to dan-petty/github-workflows").
