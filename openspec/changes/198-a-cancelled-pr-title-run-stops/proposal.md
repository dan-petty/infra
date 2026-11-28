# Proposal

## Why

Renovate changes the title of a pull request and pushes a commit at the same time, GitHub starts two runs of the PR title check on one head commit, and the job concurrency group of the reusable PR title workflow cancels one run (#198). The cancelled check run stays on the head commit beside the successful one, and Renovate merges only when each check run is `success`, `neutral` or `skipped`, so it never merges that pull request.

## What Changes

- State in the header comment of `.github/workflows/pr-title-caller.yml` that the job `pr-title` sets no concurrency key, because two title events on one head commit would cancel one run and the cancelled check run of the head commit would stop the Renovate automerge.
- Add the guard test `tests/test-pr-title-no-concurrency.sh`, which reads a workflow with the yq of `mise.toml`, prints `ok` with the path and exits 0 when no job of the file sets a `concurrency` key, and prints `FAIL` with the path and the name of each such job and exits 1 when one does.
- Run the guard test in the job `actionlint` of `.github/workflows/ci.yml`, add its path to the `actions` filter of the job `changes`, so a change of the test or of a workflow runs the job, and name the new command in the row `actionlint` of the checks table of `README.md`.
- Leave the reusable PR title workflow to dan-petty/github-workflows: the group that cancels the title check is a line of that workflow, which commit f1067fd deleted from infra, so the removal belongs to that repository, and this repository holds no such group to remove.
- Change no behavior that a consumer observes: the change touches a workflow comment, a test, a workflow step and a document, so it has no spec delta and `skip_specs` is true.
- The change fits one pull request.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

None.

## Impact

- Code: `.github/workflows/pr-title-caller.yml`, `.github/workflows/ci.yml`
- Documents: `README.md`
- Tests: `tests/test-pr-title-no-concurrency.sh`

## Feasibility

- The issue asks to remove the job concurrency group of the PR title workflow and to add a test in `tests/` that fails when a concurrency group returns; this run checked each premise with `list_files`, `read_file`, `search_code` and `find_issues` on the staged commit.
- The probes report, word for word: "The path `.github/workflows/pr-title.yml` is no file at the root of the staging commit. These files of the commit are candidates: `tests/renovate/.github/workflows/pr-title.yml`. Commit f1067fd 2026-11-27 feat: call the workflows of github-workflows (#235) deleted or renamed it."
- The probes report, word for word: "The path `tests/test-pr-title-no-concurrency.sh` is no file of the staging commit. No commit in the history deleted or renamed it."
- The probes report, word for word: "The path `README.md` is a file of the staging commit."
- The issue cannot be built as written for the removal: the tool `list_files` of `.github/workflows` gives three files, `.github/workflows/ci.yml`, `.github/workflows/pr-title-caller.yml` and `.github/workflows/release-caller.yml`, so the reusable workflow that holds the job concurrency group is no file of this repository, and the plan does not compensate for that premise and maps the removal to a person.
- Whether the reusable workflow of dan-petty/github-workflows holds the job concurrency group at the pinned commit is `not checked` in this run, because that file is no file of the staging commit and this run reached no network; the issue body states the group and its `cancel-in-progress: true`.
- The tool `read_file` of `.github/workflows/pr-title-caller.yml` shows the job `pr-title` at `.github/workflows/pr-title-caller.yml:17:` `pr-title:`, whose `uses` line `.github/workflows/pr-title-caller.yml:19:` `@39f92fb644e550f84a5797cce46a80a891231d4a # v0.1.0` calls the reusable workflow and whose job holds no `concurrency` key, so infra only calls it.
- The tool `search_code` for `concurrency` returns one workflow line, `.github/workflows/ci.yml:18:concurrency:`, and two lines of an archived design document, so no workflow of infra holds a job concurrency key.
- The tool `read_file` of `.github/workflows/ci.yml` shows the workflow-level group at `.github/workflows/ci.yml:19:group: ci-${{ github.ref }}` with `cancel-in-progress: true`; the plan keeps it, because the issue names the job concurrency of the title check.
- The tool `search_code` for `concurrency of their job` returns `No match.`, so no sentence of the staged tree says that the title caller sets a concurrency group, and the change corrects no such sentence; `README.md:138:` `PR title / Semantic PR title` is the row of the caller table that the plan leaves as it is.
- The tool `read_file` of `.github/workflows/ci.yml` lines 415 to 460 shows the job `actions` at `.github/workflows/ci.yml:425:name: actionlint`, which installs yq at `.github/workflows/ci.yml:449:run: mise install --locked actionlint shellcheck yq` and runs the check-name test at `.github/workflows/ci.yml:458:run: mise exec -- tests/test-ci-check-names.sh`, so the new guard runs in that job.
- The filter `actions` of the job `changes` holds `.github/workflows/ci.yml:96:- tests/test-ci-check-names.sh`, and group 3 adds the new test path there, so a change of the test or of a workflow runs the job `actionlint`.
- The file `mise.toml` pins the three tools that the plan relies on at `mise.toml:8:actionlint = "1.7.12"`, `mise.toml:19:shellcheck = "0.11.0"` and `mise.toml:23:yq = "4.54.3"`, and `README.md:182:actionlint` is the row of the checks table that group 3 extends.
- The tool `find_issues` for `pr-title concurrency` lists only #198, so no open item of the repository changes the same workflow, and the plan depends on no other item.
- The earlier plan named the deleted reusable workflow path in a What Changes item that no group changed; the new plan names the reusable PR title workflow of dan-petty/github-workflows in that item with no repository path, and no What Changes item names a path that no group changes or creates.
- The first criterion needs the reusable workflow of dan-petty/github-workflows, so the plan maps it to `pending-person` and copies no workflow; the second criterion is delivered by group 2, whose guard reads the caller that group 1 changes, because a test cannot read the workflow of another repository without a network and no test of infra reaches the network.
- The count of the set that the guard covers: the tool `list_files` of `.github/workflows` gives three workflow files, the guard reads one of them, `.github/workflows/pr-title-caller.yml`, the PR title caller, and the plan leaves `.github/workflows/ci.yml` and `.github/workflows/release-caller.yml` as they are.
- The fixture caller `tests/renovate/.github/workflows/pr-title.yml` is the render of the repository template of dan-petty/github-workflows for the Renovate preset test, it holds no concurrency key, and it never runs, so the guard does not read it.
- The guard test reads one file of the checkout with yq, reaches no network, no cluster and no scanner, writes nothing outside the checkout and doubles no process edge, so it runs offline.
- The plan calls no function whose arguments need a checkout, a client or a network: it adds a comment, a shell script, a workflow step and a README command.
- Runner capability of the program that the plan introduces: `tests/test-pr-title-no-concurrency.sh` is a file of the repository that runs with `bash` of the image and calls `yq`, which is `NOT_IN_RUNNER`; `actionlint` and `shellcheck` come from the image; the stage pod has a read-only root and no cluster token, so the guard runs in the job `actionlint` and by hand on a workstation, never in the stage pod.
- Failure classes: a guard that reports a concurrency key is `test`, `mise exec -- actionlint` that fails is `lint`, and a `mise exec --` step that cannot install from the registry is `provider`.
- The first checks that the implementation runs against the real system, in a checkout with the tools of `mise.toml` installed: `mise install --locked`, then `mise exec -- actionlint`, which exits 0, and `mise exec -- tests/test-pr-title-no-concurrency.sh`, which prints `ok` with `.github/workflows/pr-title-caller.yml` and exits 0.

## Existing Tool Considered

No open tool covers the need: the alternatives block of the issue body records the verdict `none`, actionlint 1.7.12 and zizmor check the syntax and the security of a workflow but hold no rule for the absence of a job-level concurrency key, and yq only reads keys. The change therefore builds its own guard: about 1,500 tokens and 30 minutes to write, keep and fix the 40-line shell test, and it deletes no internal code.

## Dependencies

None.
