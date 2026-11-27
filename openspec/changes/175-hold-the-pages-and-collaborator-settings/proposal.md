# Proposal

## Why

The template holds the GitHub baseline of each new repository of dan-petty, and `devops repos onboard` renders it (#175). The schema can name an environment but no Pages site and no collaborator, and the template renders neither, so a new repository gets its site and its collaborators by hand. Row 5 of `devops repos onboard` already applies each environment of the baseline, so the environment `github-pages` takes effect at the next run of the command. No row of the command reads a `pages` key or a `collaborators` key yet: dan-petty/devops-cli#5325 adds those rows. Until it merges, the two keys are data that no row applies. #188 renders the exact answers of dan-petty/devops-cli.

## What Changes

- Add the `pages` object, with the fields `build_type`, `source`, `cname` and `https_enforced`, to `templates/github-repository.schema.json`. The schema requires `source` when `build_type` is `legacy`.
- Add the `collaborators` array and the `collaborator` definition, with `username` and `permission`, to `templates/github-repository.schema.json`.
- Add the `pages` answer with default false and the `collaborators` answer with the validator of a `username:permission` pair to `copier.yml`.
- Render the `pages` key, each collaborator and the environment `github-pages` in `templates/repository/github/repository.yaml.jinja`, and render `environments` when `release_flow` or `pages` is true. An empty `collaborators` answer renders no `collaborators` key.
- Add the `pages` case, the collaborator refusal case, and the default checks for no `pages` key and no `collaborators` key to `tests/test-repository-template.sh`.
- Describe the two answers and the two keys in `templates/README.md`, and rewrite its `environments` row and its Test section for the new answer.
- Keep the exact Pages and collaborator values of dan-petty/devops-cli in that repository; #188 renders and asserts them.
- The change fits one pull request.

## Capabilities

### New Capabilities

- `repository-template`: The settings schema names a Pages site, The settings schema names the collaborators, The pages answer renders the site and its environment, The collaborators answer renders each collaborator, The default answers render no site and no collaborator, Copier refuses an invalid collaborator answer, The template holds no private value

### Modified Capabilities

None.

## Impact

- Code: `templates/github-repository.schema.json`, `copier.yml`, `templates/repository/github/repository.yaml.jinja`
- Documents: `templates/README.md`
- Tests: `tests/test-repository-template.sh`

## Feasibility

- The probes answer, word for word, The path `templates/github-repository.schema.json` is a file of the staging commit., The path `templates/repository/github/repository.yaml.jinja` is a file of the staging commit., The path `copier.yml` is a file of the staging commit., The path `tests/test-repository-template.sh` is a file of the staging commit. and The path `tests/test-private-data-scan.sh` is a file of the staging commit., so each file that the plan changes or names as a guard exists at the staged commit.
- The probes answer, word for word, The path `github/repository.yaml` is a file of the staging commit., so the baseline of infra exists; the plan changes no line of it, because the site and the collaborators of infra stay its own answers.
- `search_code` with the text `collaborators` answered `No match.`, and `search_code` with the text `github-pages` answered `No match.`, so no file of the staged commit holds either name and the plan creates both.
- `search_code` with the text `{%- if release_flow %}` answered `templates/repository/github/repository.yaml.jinja:92:{%- if release_flow %}` and `templates/repository/.github/labels.yml.jinja:27:{%- if release_flow %}`, so the settings baseline renders `environments` under the release flow only, and the plan widens that condition to `release_flow or pages`; the labels file keeps its own guard and no group changes it.
- `search_code` with the text `no environment` answered `tests/test-repository-template.sh:140:expect "defaults: no environment" "0" \`, so the default case asserts no environment and the plan keeps that case true with a default `pages` of false.
- `search_code` with the text `code_coverage:` answered `copier.yml:64:code_coverage:` and `.copier-answers.yml:4:code_coverage: false`, so the answers of the template sit in `copier.yml`, the plan adds `pages` and `collaborators` there, and `.copier-answers.yml` is written by Copier and needs no edit.
- `read_file` of `templates/README.md` lines 18 to 30 showed the question table header at `templates/README.md:24:| Question | Default | Content |`, and `read_file` of lines 52 to 70 showed the settings table header at `templates/README.md:58:| Key | Endpoint | Baseline |`, so group 4 adds one row to each table. `templates/README.md:67` says that `environments` renders "With the release flow only", and `templates/README.md:91` lists the answer sets of the test without a Pages case, so group 4 rewrites both.
- Each group names the file that it changes in a code span of its task.
- `read_issue` for #203 answered that it is an open Renovate pull request that changes `github/repository.yaml`, the rendered baseline of infra itself; this plan changes no line of that file and does not depend on that pull request, so the two land in either order.
- The consumer of the keys: a case-blind search of the onboard package of dan-petty/devops-cli on `main` for `pages` and `collaborator` finds no match, so no row of `devops repos onboard` reads the two keys. Row 5 (`environment_row` in the settings rows of the command) writes each item of `environments`, so it applies `github-pages` with no change in devops-cli. The command checks the rendered file against `templates/github-repository.schema.json` of the same tag, so a new key of the schema does not make the baseline unreadable. dan-petty/devops-cli#5325 is open and adds the Pages row and the collaborator row.
- The live site of dan-petty/devops-cli: `GET /repos/dan-petty/devops-cli/pages` answers `build_type: workflow` and `https_enforced: true`, and its environment `github-pages` answers `custom_branch_policies: true`, `protected_branches: false` and the one branch policy `main`. The render of `pages=true` gives the same build type and the same environment.
- The collaborator endpoint: the GitHub REST documentation of "Add a repository collaborator" says that `permission` is "Only valid on organization-owned repositories", and lists `pull`, `triage`, `moderate`, `push`, `maintain` and `admin`. `GET /users/dan-petty` answers `type: User`, so on a repository that dan-petty owns GitHub grants `push` (the role `write`) for each answer, and the README row says so.
- The checks: `uv run devops ci --check --only template` and `uv run devops ci --check --only private-data` exit 2 with `Unknown check row` (devops-cli 0.224.2): `devops ci` runs the rows of devops-cli only, and `uv run devops ci docs` checks the documents of devops-cli, not of infra. The checks of this change are the commands of README.md, "Checks": `mise exec -- tests/test-repository-template.sh` (CI job `template`, "Repository template"), and `mise exec -- tests/test-private-data-scan.sh` with `mise exec -- scripts/private-data-scan.sh dir .` (CI job `private-data`). The plan reader takes no `mise` command on a `Verification:` line, so each group gives these commands as a check by hand.
- Preconditions of those calls: a checkout of the repository, `mise install --locked` and `uv sync --frozen`. The `pages` case and the refusal case render the working tree with no network; the whole test needs a network, because it calls `npx` for the Renovate validator and `check-jsonschema` reads the release-please schemas from a URL. The private-data guard needs no network. Each scenario names the render `uv run copier copy --vcs-ref HEAD` and the validator `uv run check-jsonschema`: both are in the `dev` group of `pyproject.toml` (copier 9.19.1, check-jsonschema 0.39.0), and both ran with no network (`unshare -rn`) on the staged tree.
- Runner capability: `uv`, `python`, `devops`, `git`, `node`, `npm`, `jq`, `actionlint`, `shellcheck`, `pre-commit` and `gitleaks` are image tools; `copier`, `check-jsonschema` and `yamllint` come from the virtual environment that `uv sync --frozen` writes; `mise` and `yq` are `NOT_IN_RUNNER` for the gate, so the render runs in the workflow job that installs them, and the plan introduces no program of its own.
- Failure classes of the verify: a failed `check` case makes `tests/test-repository-template.sh` exit non-zero, `check-jsonschema` exits non-zero on a schema mismatch, the refusal case passes only when `copier copy` exits non-zero, and the private-data guard exits 1 on a finding.
- The validator of the new answer reuses `regex_search`, which the validator of `scopes` in `copier.yml` already calls, so the change raises no Copier version bound and relies on no integer constant of the staged tree; `constant_claims` is empty.
- The body holds no person-written list under a heading `Acceptance criteria` before the refine block, so `criteria` stays empty.
- The new test case names `example-user` and the schema names no repository, so the private-data guard keeps passing and no private value enters the repository.

## Existing Tool Considered

Copier, which `tests/test-repository-template.sh` already renders with, takes the two answers and refuses an invalid one with the validator of `copier.yml`, and check-jsonschema, which the test already calls, validates each render against `templates/github-repository.schema.json`; both are open and maintained, so the change adds no program, at a written cost of about 15k tokens and about two hours to build, keep and fix the schema keys, the template blocks and the cases. The change deletes no internal code.

## Dependencies

None.
