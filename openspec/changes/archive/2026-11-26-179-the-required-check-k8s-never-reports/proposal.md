# Proposal: the required check K8s never reports

## Why
The ruleset of `main` requires the check `K8s` (#179). GitHub names the check of a job that calls a reusable workflow `<job>` only when the job is skipped, and `<job> / <called job>` when it runs. So a pull request that changes the Kubernetes files never gets `K8s`, and cannot merge.

## What Changes
- The job that calls `k8s-validate.yml` is `k8s-validate`, with the name `K8s run`.
- A job `k8s`, with the name `K8s`, runs on every event and fails when the validation or the job `changes` did not succeed or get skipped.
- `tests/test-ci-check-names.sh` holds the rule for each conditional job that calls a reusable workflow.

## Capabilities
- `ci-check-names` (new): the check names of `ci.yml` that a ruleset can require.

## Impact
The ruleset needs no change. A pull request that is open now takes the new check after its branch holds this change.

## Feasibility
Confirmed on 2026-11-26 with the check runs that GitHub returns: #176 and #177, with no Kubernetes change, report `K8s` as skipped, and #178 reports `K8s / Validate` and no `K8s`.

## Existing Tool Considered
GitHub job results (`needs.<job>.result`) with `if: always()`, and `yq` for the test. No new tool. This change deletes no code. It fits one pull request.
