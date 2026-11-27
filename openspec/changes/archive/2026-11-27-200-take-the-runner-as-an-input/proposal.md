# Proposal: a caller selects the runner of a reusable workflow

## Why

The reusable workflows `k8s-validate.yml` and `pr-title.yml` run their job on `ubuntu-26.04` and take no runner input (#200). A private caller then uses Actions minutes for each run, also when it has its own runner. When the included minutes of the account are used, these jobs do not start. A job that calls a reusable workflow cannot set `runs-on`, so only the called workflow can select the runner. dan-petty/homelab#460 needs the input for the title check and the job `k8s-validate`.

## What Changes

- `k8s-validate.yml` and `pr-title.yml` declare the `string` input `runs-on`, with the default empty.
- Each job runs on `${{ inputs.runs-on || 'ubuntu-26.04' }}`. A caller that passes no input or an empty value keeps the runner `ubuntu-26.04`.
- `README.md` and the comments of the two workflows describe the input, and the condition of GitHub for a self-hosted runner of the caller.
- The callers of infra pass no input and keep their runner.

## Capabilities

- `reusable-workflow-runner` (new): the runner of the job of a reusable workflow of infra.

## Impact

A caller gets the input when its pin of infra moves to the release that holds this change. The input is optional, so no caller must change. `release.yml` keeps its fixed runner. The change fits one pull request.

## Feasibility

Confirmed on 2026-11-27 against the GitHub documentation and the tools of the repository:

- "Contexts reference", Context availability: `jobs.<job_id>.runs-on` allows the contexts `github`, `needs`, `strategy`, `matrix`, `vars` and `inputs`.
- "Workflow syntax", `on.workflow_call.inputs.<input_id>.type`: "This must be one of: `boolean`, `number`, or `string`." `jobs.<job_id>.runs-on` accepts "A single variable containing a string".
- "Reusing workflow configurations": the list of keywords of a job that calls a reusable workflow holds no `runs-on`. "Called workflows that are owned by the same user or organization as the caller workflow can access self-hosted runners from the caller's context."
- "Contexts reference", `vars` context: "If a configuration variable has not been set, the return value of a context referencing the variable will be an empty string."
- "Use ARC in a workflow": a job targets a runner scale set by its installation name, such as `runs-on: arc-runner-set`.
- actionlint 1.7.12 on the base refuses a caller that passes `runs-on` to the two workflows: `input "runs-on" is not defined in "./.github/workflows/pr-title.yml" reusable workflow`. With the change, it reports no error. zizmor 1.33.1 (`--offline`, also with `--persona=auditor`) reports no finding for the two workflows.

## Existing Tool Considered

The input of `workflow_call` and the expression `||` of GitHub Actions cover the need. The alternatives check of 2026-11-27 in #200 found no tool. No code is built, so the change has no build, upkeep or fix cost. This change deletes no code.
