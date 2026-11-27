# Proposal

## Why

The template holds the GitHub baseline of each new repository of dan-petty, and `devops repos onboard` renders it (#175). The schema can name an environment but no Pages site and no collaborator, and the template renders neither, so a new repository gets its site and its collaborators by hand. #188 renders the exact answers of dan-petty/devops-cli.

## What Changes

- Add the `pages` object, with the fields `build_type`, `source`, `cname` and `https_enforced`, to `templates/github-repository.schema.json`.
- Add the `collaborators` array and the `collaborator` definition, with `username` and `permission`, to `templates/github-repository.schema.json`.
- Add the `pages` answer with default false and the `collaborators` answer with the validator of a `username:permission` pair to `copier.yml`.
- Render the `pages` key, each collaborator and the environment `github-pages` in `templates/repository/github/repository.yaml.jinja`, and render `environments` when `release_flow` or `pages` is true.
- Add the `pages` case and the collaborator refusal case to `tests/test-repository-template.sh`.
- Describe the two answers and the two keys in `templates/README.md`.
- Keep the exact Pages and collaborator values of dan-petty/devops-cli in that repository; #188 renders and asserts them.
- The change fits one pull request.

## Capabilities

### New Capabilities

- `repository-template`: The settings schema names a Pages site, The settings schema names the collaborators, The pages answer renders the site and its environment, The collaborators answer renders each collaborator, Copier refuses an invalid collaborator answer, The template holds no private value

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
- `read_file` of `templates/README.md` lines 18 to 30 showed the question table header at `templates/README.md:24:| Question | Default | Content |`, and `read_file` of lines 52 to 70 showed the settings table header at `templates/README.md:58:| Key | Endpoint | Baseline |`, so group 5 adds one row to each table.
- The reported fault was that group 4 packed no file: its text named no path of the staged commit. Group 4 now names `templates/repository/github/repository.yaml.jinja` in a code span of its implementation, and each other group names the file it changes in a code span.
- `read_issue` for #203 answered that it is an open pull request with the shared path `github/repository.yaml`; this plan changes no line of that file, so the two land in either order.
- The consumer render is not checked in this run: the issue itself moves it to #188, which holds the answers of dan-petty/devops-cli, and this plan hardcodes no value of that repository.
- The probes answer, word for word, The path `vX.Y.Z` is no file of the staging commit. No commit in the history deleted or renamed it., so the release tag of the issue is no path of the tree; the plan writes no tag, and the release workflow of `.github/workflows/release.yml` writes it after the merge.
- First checks against the real system: `uv run devops ci --check --only template` runs the job `template` with `tests/test-repository-template.sh`, and `uv run devops ci --check --only private-data` runs `tests/test-private-data-scan.sh` with `scripts/private-data-scan.sh`.
- Preconditions of those calls: `uv run devops ci --check --only template` needs a checkout of the repository and a network, because the test calls `npx` for the Renovate validator and `check-jsonschema` reads the release-please schemas from a URL; `uv run devops ci --check --only private-data` needs a checkout of the repository and no network.
- Runner capability: `uv`, `python`, `devops`, `git`, `node`, `npm`, `jq`, `actionlint`, `shellcheck`, `pre-commit` and `gitleaks` are image tools; `copier`, `check-jsonschema` and `yamllint` come from the virtual environment that `uv sync --frozen` writes; `mise` and `yq` are `NOT_IN_RUNNER` for the gate, so the render runs in the workflow job that installs them, and the plan introduces no program of its own.
- Failure classes of the verify: a failed `check` case makes `tests/test-repository-template.sh` exit non-zero, `check-jsonschema` exits non-zero on a schema mismatch, the refusal case passes only when `copier copy` exits non-zero, and the private-data guard exits 1 on a finding.
- The validator of the new answer reuses `regex_search`, which the validator of `scopes` in `copier.yml` already calls, so the change raises no Copier version bound and relies on no integer constant of the staged tree; `constant_claims` is empty.
- The body holds no person-written list under a heading `Acceptance criteria` before the refine block, so `criteria` stays empty.
- The new test case names `example-user` and the schema names no repository, so the private-data guard keeps passing and no private value enters the repository.

## Existing Tool Considered

Copier, which `tests/test-repository-template.sh` already renders with, takes the two answers and refuses an invalid one with the validator of `copier.yml`, and check-jsonschema, which the test already calls, validates each render against `templates/github-repository.schema.json`; both are open and maintained, so the change adds no program, at a written cost of about 15k tokens and about two hours to build, keep and fix the schema keys, the template blocks and the cases.

## Dependencies

- #203: open pull request that changes `github/repository.yaml`, the shared path of the overlap; this plan changes no line of that file, so the two land in either order.
