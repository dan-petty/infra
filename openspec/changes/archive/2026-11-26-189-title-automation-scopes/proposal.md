# Proposal: the title check accepts the scopes of the shared automation

## Why
The reusable workflow `pr-title.yml` takes the allowed scopes from the `scope/*` labels of the caller, and `main` (#189). A repository that declares no scope label then refuses each scope but `main`. So the title `chore(deps): ...` that the shared Renovate preset writes fails the check. The title check also reads the subject of the one commit of a pull request, so a plan pull request with the commit `docs(spec): ...` fails too.

A `chore(deps)` title also fails when its summary has more than 60 characters. The shared preset names an image by its full reference, such as `update ghcr.io/dan-petty/devops-cli/service Docker tag to v0.221.15`, which has 67 characters. In infra, `.github/labels.yml` also lacks scopes that issue titles use.

## What Changes
- `scripts/pr-title-scopes.sh` prints `ci`, `deps`, `docs`, `main` and `spec` for every repository, and the `scope/*` labels of the file, each one time.
- A missing labels file, or a file with no list, still fails.
- Each type of Conventional Commits stays allowed. The scope check, the single commit check and the limit of 60 characters stay.
- The comments and `README.md` describe the list.
- `renovate/base.json` names an image with a registry host by the last two parts of its reference, and a digest title leaves out the tag. `renovate/README.md` describes it.
- `.github/labels.yml` of infra declares `scope/security`, `scope/terraform`, `scope/templates` and `scope/tools`.

## Capabilities
- `pr-title-scopes` (new): the scopes that the title check accepts.
- `renovate-titles` (new): the length of the titles that the shared preset gives an image update.

## Impact
A caller gets the scopes when its pin of infra moves to the release that holds this change. It needs no new label. A repository that extends `renovate/base` with no release tag gets the short titles when this change is on `main`. An open update pull request gets the new commit subject only when Renovate writes its branch again. The change fits one pull request.

## Feasibility
Confirmed on 2026-11-26 on the base: `mise exec -- scripts/pr-title-scopes.sh` (yq 4.54.3) on a labels file with no `scope/*` label prints only `main`. `renovate/base.json` sets `commitMessagePrefix` to `chore(deps):`, and `fix(deps):` for a vulnerability alert. The workflow gives the output of the script to the input `scopes` of `action-semantic-pull-request` v6.1.4.

The functions `flattenUpdates` and `generateBranchConfig` of Renovate 44.263.6 give for the base preset the title of homelab#327 with a summary of 67 characters. With the new rule, the summary of that update has 49 characters, and that of `quay.io/argoproj/workflow-controller` v4.1.7 has 56.

## Existing Tool Considered
`action-semantic-pull-request` stays the check, and `yq` stays the reader of the labels file. Its input `scopes` takes the whole list, so the change adds five values to the `yq` expression. The option `commitMessageTopic` and the template helpers `replace` and `equals` of Renovate shorten the title. No new tool. This change deletes no code.
