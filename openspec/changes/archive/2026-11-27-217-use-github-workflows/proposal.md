# Proposal: call the workflows of dan-petty/github-workflows

## Why
Each onboarded repository pins dan-petty/infra two times, for the reusable workflows and for the Copier template, and each release of infra opens a pin pull request in each repository, also when no workflow and no template file changed (#217). The workflows and the template moved to the new public repository dan-petty/github-workflows, which releases only when they change (its release `v0.1.0`, dan-petty/github-workflows#3). infra still holds the old copies, calls its own copies, and its Renovate presets name only infra.

Owner, 2026-11-27: "standardize templates and workflows where possible" and "don't build custom solutions where standard conventions already cover the use cases".

## What Changes
- Delete the moved files from infra: the reusable workflows `pr-title.yml`, `release.yml` and `k8s-validate.yml`, `clear-status.yml` (the Service removes the labels, owner decision on #217), `scripts/pr-title-scopes.sh`, `scripts/k8s-validate.sh`, `.kube-linter.yaml`, `copier.yml`, `templates/`, their tests, the CI jobs `kube-linter config` and `Repository template`, the zizmor config and the actionlint entries of the deleted workflows.
- `ci.yml`, `pr-title-caller.yml` and `release-caller.yml` call `k8s-validate.yml`, `pr-title.yml` and `release.yml` of dan-petty/github-workflows at the commit of `v0.1.0`, with the job names of the required checks. Renovate moves these pins: infra holds no render of the template.
- `tests/test-service-repos.sh` runs kubeconform itself, with the CRD catalog of the deleted script.
- `renovate/base.json`: the title rules name dan-petty/github-workflows and its template; the rule of #225 names the callers of dan-petty/github-workflows; a new rule turns off the github-actions manager and the copier manager for infra, because a newer release of infra holds no workflow and no template. `renovate/k8s.json`: the group `infra` names no workflow.
- Remove Copier and check-jsonschema from `pyproject.toml` and `uv.lock`.
- Delete the specs `template-file-owners`, `template-workflow-pins` and `reusable-workflow-runner`: dan-petty/github-workflows holds them at `v0.1.0`. `pr-title-scopes` keeps only the scopes of infra.
- Correct README.md, `renovate/README.md`, `helm/README.md`, `k8s/tests/README.md` and the comments that name a deleted file.

## Capabilities
- `pr-title-scopes` (modified): two requirements of the script leave; the scopes of infra stay, checked by the script of dan-petty/github-workflows.
- `renovate-copier` (modified): the copier rules name dan-petty/github-workflows, and Renovate leaves each workflow caller and each copier render of infra alone.
- `renovate-titles` (modified): the title of a pin of dan-petty/github-workflows and of its template.

## Impact
- A person removes the required checks `Repository template` and `kube-linter config` from the ruleset `main` of infra before the merge: the jobs no longer exist, so the checks never report.
- Each consumer moves once to dan-petty/github-workflows (`renovate/README.md`, "Move to dan-petty/github-workflows"): a recopy with the new `_src_path`, and a new `uses:` line for each caller of `k8s-validate.yml` (dan-petty/homelab, dan-petty/danielpetty.com). Until then Renovate leaves their pins of infra alone.
- The change fits one pull request.

## Feasibility
Confirmed on 2026-11-27:
- `git rev-parse v0.1.0^{commit}` in dan-petty/github-workflows gives `39f92fb644e550f84a5797cce46a80a891231d4a`. Its `k8s-validate.yml` has each input of the call of `ci.yml`, its `scripts/k8s-validate.sh` differs from the script of infra only in comments and one variable name, and its `mise.toml` pins the same versions of the tools of the workflow.
- The script of dan-petty/github-workflows `v0.1.0`, run with the inputs of `ci.yml` and the tools of `mise.lock` of infra, validates each Kustomize root, chart and rule file of infra.
- Copier 9.19.1: a render of the template of infra at `v0.24.1`, updated with `copier update --vcs-ref` to a tag with no `copier.yml` and no `templates/`, exits 0, deletes 4 files of the template and writes 36 files of the root of infra. A recopy with `_src_path` of dan-petty/github-workflows and `--vcs-ref v0.1.0` renders the callers of dan-petty/github-workflows.
- Renovate 45.1.0 `--platform=local --dry-run=lookup` of `tests/renovate/`: each caller and each copier render of infra gets the skip reason `disabled`, and each pin of dan-petty/github-workflows gets its repository with no warning.
- The live ruleset `main` of infra requires `Repository template` and `kube-linter config`.

## Existing Tool Considered
The reusable workflows of dan-petty/github-workflows replace the copies of infra, kubeconform replaces the call of the deleted script in `tests/test-service-repos.sh`, and the documented Renovate options `matchManagers`, `matchPackageNames`, `matchFileNames`, `enabled` and `commitMessageTopic` replace nothing custom. No script is added. The change deletes `scripts/pr-title-scopes.sh`, `scripts/k8s-validate.sh`, `copier.yml`, `templates/`, four workflows and four tests.
