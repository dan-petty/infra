# Design

## Decisions

- **Name the input `runs-on`, with the type `string`.**: The name is the key that it sets, in the kebab-case of the other inputs of `k8s-validate.yml`. A `workflow_call` input is a boolean, a number or a string, and `runs-on` accepts "A single variable containing a string" ("Workflow syntax").
- **Default empty, and run the job on `${{ inputs.runs-on || 'ubuntu-26.04' }}`.**: The `vars` context gives an empty string for a variable that is not set ("Contexts reference"), and an empty label is no runner. With the fallback, a caller can pass `${{ vars.RUNNER }}`, and the runner of today stays in one place, the workflow. Empty also selects the default in the other inputs of `k8s-validate.yml`.
- **Keep the callers of infra as they are.**: `ci.yml` and `pr-title-caller.yml` pass no input, so the checks of each pull request of infra run the default path. infra has no runner of its own.
- **Keep the label `ubuntu-26.04` in `.github/actionlint.yaml`.**: The other jobs of infra still name it (`ci.yml`, `release.yml`, `clear-status.yml`). actionlint does not check the label of a `runs-on` value that is an expression.

## Rejected alternatives

- **Default `ubuntu-26.04` and `runs-on: ${{ inputs.runs-on }}`.**: An empty value, such as `${{ vars.RUNNER }}` with no variable, then gives the job no runner label. Each caller must then repeat the label, as in `${{ vars.RUNNER || 'ubuntu-26.04' }}`.
- **A JSON array in the input, with `fromJSON(inputs.runs-on)`.**: No input type is an array ("Workflow syntax"), so each caller must write JSON, also for one label. A job targets a runner scale set by its installation name ("Use ARC in a workflow"). A scale set can also have more labels, but no caller uses them. A later input can add an array form with no change for the callers of `runs-on`.
- **Set `runs-on` in the job of the caller.**: The keywords of a job that calls a reusable workflow are `name`, `uses`, `with`, `secrets`, `strategy`, `needs`, `if`, `concurrency`, `permissions` and `cache-mode` ("Reusing workflow configurations"). actionlint 1.7.12 refuses `runs-on` in such a job: `when a reusable workflow is called with "uses", "runs-on" is not available`.
- **Add the input to `release.yml` too.**: No caller of another repository calls it: a code search of the owner on 2026-11-27 found only `release-caller.yml` of infra and the template `templates/repository/.github/workflows/release.yml.jinja`. Its job also holds the private key of the release App, so a move to a self-hosted runner needs its own decision.

## Security

The input changes only the runner of the job. The permissions of each job stay `contents: read`, and `pull-requests: read` for the title check. GitHub gives a called workflow the self-hosted runners of the caller only when the caller and infra have the same owner ("Reusing workflow configurations"). The callers of infra pass no input, so a pull request of infra, also from a fork, runs on a GitHub-hosted runner. A caller that selects its own runner gives that runner the token of the job and the content of the pull request; the caller decides which pull requests start the job.
