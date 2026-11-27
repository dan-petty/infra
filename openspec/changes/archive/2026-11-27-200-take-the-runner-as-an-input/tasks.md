# Tasks

## 1. Workflows

- [x] 1.1 Check that actionlint refuses a caller that passes `runs-on` to the two workflows on the base
  - Verification: write a caller workflow that calls `./.github/workflows/pr-title.yml` and `./.github/workflows/k8s-validate.yml` with `runs-on`, put it into `.github/workflows/` of a copy of the base, and run `mise exec -- actionlint` on it: it reports `input "runs-on" is not defined` for each call. On a copy with the change, it reports no error.
- [x] 1.2 Declare the input `runs-on` in `k8s-validate.yml` and `pr-title.yml`, and run each job on `${{ inputs.runs-on || 'ubuntu-26.04' }}`
  - Verification: `$ mise exec -- actionlint`
- [x] 1.3 Check the two workflows with zizmor
  - Verification: `$ .venv/bin/zizmor --offline .github/workflows/`
- [x] 1.4 Check that a caller with no input runs on `ubuntu-26.04`
  - Verification: read the jobs of a run of `CI` and of `PR Title` on a pull request with this change: `gh api repos/dan-petty/infra/actions/runs/<run-id>/jobs --jq '.jobs[] | "\(.name) \(.labels)"'` gives `["ubuntu-26.04"]` for `K8s run / Validate` and `PR title / Semantic PR title`.

## 2. Documents

- [x] 2.1 Describe the input in `README.md` and in the comments of the two workflows
  - Verification: `$ .venv/bin/yamllint --strict .`
- [x] 2.2 Keep the rendered repository template passing
  - Verification: `$ mise exec -- tests/test-repository-template.sh`

## Workflow follow-up

- The live proof that a caller that passes `runner-homelab` runs on that runner: #206.
- The move of the pins of a consumer to the release with the input, and the input in its calls: dan-petty/homelab#460.
