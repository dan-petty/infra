## Purpose

The runner of the job of each reusable workflow of infra that a caller can move to its own runner, and the GitHub-hosted runner that a caller gets when it selects none.

## ADDED Requirements

### Requirement: A caller selects the runner of a reusable workflow
The reusable workflows `k8s-validate.yml` and `pr-title.yml` SHALL declare the `string` input `runs-on`, and SHALL run their job on the runner label that the input gives.

#### Scenario: A caller passes a runner label
- **WHEN** a caller workflow passes `runs-on` to `./.github/workflows/k8s-validate.yml` and to `./.github/workflows/pr-title.yml`
- **THEN** `mise exec -- actionlint` on that caller reports no error

#### Scenario: A caller passes the name of its runner scale set
- **WHEN** a caller with the same owner as infra passes the name of its runner scale set in `runs-on`
- **THEN** the live check of the jobs of the run, `GET /repos/<owner>/<repo>/actions/runs/<run-id>/jobs`, gives that name in the labels of the job

### Requirement: An empty runner input keeps the GitHub-hosted runner
When a caller passes no `runs-on` input, or an empty value, the job SHALL run on the GitHub-hosted runner `ubuntu-26.04`.

#### Scenario: A caller passes no runner input
- **WHEN** `ci.yml` calls `k8s-validate.yml` and `pr-title-caller.yml` calls `pr-title.yml` with no `runs-on` input
- **THEN** the live check of the jobs of the run gives the label `ubuntu-26.04` for the jobs `K8s run / Validate` and `PR title / Semantic PR title`
