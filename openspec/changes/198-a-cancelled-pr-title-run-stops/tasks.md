# Tasks

## 1. State in the PR title caller that its job sets no concurrency group

Kind: other. Reads: `.github/workflows/pr-title-caller.yml`. Changes: `.github/workflows/pr-title-caller.yml`.

- [ ] 1.1 Add three comment lines to the header block of `.github/workflows/pr-title-caller.yml`, above the `on` key: the job `pr-title` sets no `concurrency` key, two title events on one head commit would cancel one run, and the cancelled check run of the head commit stops the Renovate automerge. Keep the `name`, `on`, `permissions` and `jobs` keys, the job `pr-title` and its `uses` line as they are, and give the reason for the rule in the comment, and run this check by hand: On a workstation with a checkout of the repository and the tools of `mise.toml`, run `mise install --locked`, then `mise exec -- actionlint`: it exits 0. Read the header comment of `.github/workflows/pr-title-caller.yml`: it states that the job sets no concurrency key and gives the reason. Run `git grep -n -F 'concurrency:' .github/workflows/pr-title-caller.yml`: it prints no line and exits 1.

## 2. Add the guard test for a job concurrency group

Kind: other. Reads: `.github/workflows/pr-title-caller.yml`, `tests/test-ci-check-names.sh`. Changes: `tests/test-pr-title-no-concurrency.sh` (new).

- [ ] 2.1 Create `tests/test-pr-title-no-concurrency.sh` as a bash script with `set -euo pipefail` and a header comment that names `.github/workflows/pr-title-caller.yml` and the cancelled check run. The script takes an optional workflow path, defaults to that caller under the root of the script, and runs `yq '[.jobs[] | select(has("concurrency"))] | length'` on the path. It fails when the file holds no job, prints `ok` with the path and exits 0 when the count is 0, and prints `FAIL` with the path and the name of each job that sets a `concurrency` key and exits 1 otherwise, and run this check by hand: On a workstation with a checkout of the repository and the tools of `mise.toml`, run `mise install --locked`, then `mise exec -- tests/test-pr-title-no-concurrency.sh`: it prints `ok` with `.github/workflows/pr-title-caller.yml` and exits 0. Run `mise exec -- shellcheck tests/test-pr-title-no-concurrency.sh`: it reports nothing. Copy the caller to a file outside the repository, add a `concurrency` block under the job `pr-title`, and run `mise exec -- tests/test-pr-title-no-concurrency.sh` with the path of that copy as its argument: it prints `FAIL` with the path and exits 1.

## 3. Run the guard test in the actionlint job and name it in the checks table

Kind: other. Reads: `.github/workflows/ci.yml`, `README.md`. Changes: `.github/workflows/ci.yml`, `README.md`.

- [ ] 3.1 In `.github/workflows/ci.yml`, add a step that runs `mise exec -- tests/test-pr-title-no-concurrency.sh` to the job `actions`, whose name is `actionlint`, after the step that runs `tests/test-ci-check-names.sh`, and add the path `tests/test-pr-title-no-concurrency.sh` to the filter `actions` of the job `changes`, so a change of the test or of a workflow runs the job. In `README.md`, add `mise exec -- tests/test-pr-title-no-concurrency.sh` to the command cell of the row `actionlint` of the checks table, and run this check by hand: On a workstation with a checkout of the repository and the tools of `mise.toml`, run `mise install --locked`, then `mise exec -- actionlint`: it exits 0. Read the job `actions` of `.github/workflows/ci.yml`: it holds the new step after the step of `tests/test-ci-check-names.sh`, and the filter `actions` of the job `changes` holds the path `tests/test-pr-title-no-concurrency.sh`. Read the row `actionlint` of the checks table of `README.md`: it names `mise exec -- tests/test-pr-title-no-concurrency.sh`.
- [ ] 3.2 Edit `README.md`
  - Verification: `$ uv run devops ci docs` passes

## Criteria

- Pending person: Two title events on one head commit leave no cancelled check run., The group that cancels the run is a line of the reusable workflow that dan-petty/github-workflows holds: commit f1067fd deleted or renamed that workflow in infra, and `.github/workflows/pr-title-caller.yml` only calls it at a release pin, so a person removes the group in that repository and confirms two title events after the merge.
- Group 2: A test in `tests/` fails if the workflow gets a concurrency group again.
