# Repository template

This folder holds the [Copier](https://copier.readthedocs.io/) template of a new repository of
dan-petty. `copier.yml` in the repository root holds the questions, and Copier renders only the
files of `templates/repository/` (`_subdirectory`). `github-repository.schema.json` is the schema
of the settings baseline `github/repository.yaml`. The consumer is the command
`devops repos onboard` of devops-cli (devops-cli#6773). It renders the template into each new
repository, opens the template pull request, and applies the settings baseline to the repository.

## Render a repository

```sh
copier copy --vcs-ref vX.Y.Z --data scopes=api,worker https://github.com/dan-petty/infra.git <dir>
```

- `--vcs-ref vX.Y.Z` selects the release tag of infra. Without it, Copier renders the newest tag.
- Use the HTTPS URL of the repository. Copier writes it into `_src_path` of `.copier-answers.yml`,
  and the copier manager of Renovate looks up the tags of that URL with the datasource `git-tags`.
  Renovate cannot read the short form `gh:dan-petty/infra`.
- The template has no `_tasks` and no `_jinja_extensions`, so Copier runs it without `--trust`.
- `--defaults` gives the default answer of each question that `--data` does not give, with no
  prompt.

| Question | Default | Content |
| --- | --- | --- |
| `release_flow` | `false` | Make releases with release-please. With `false`, the repository gets no release workflow, no release-please files and no environment `release`. A private repository on the GitHub Free plan has no environments, and the key of the release App never goes into a repository secret (devops-cli#6773, decision D2). So the default is `false`, and the caller answers `true` for a repository with environments. |
| `release_type` | `simple` | The release type of release-please: `simple`, `python` or `node`. Only `simple` gets `version.txt`. A `python` or `node` repository holds its version in its `pyproject.toml` or `package.json`. Copier asks it only when `release_flow` is `true`. |
| `scopes` | empty | The Conventional Commit scopes of the repository, separated by commas. Each scope gets a label `scope/<scope>`. The template always adds `ci`, `deps` and `docs`. Copier refuses a scope that is not a lowercase name, and the scope `main` of the release pull request. |
| `code_owner` | `@dan-petty` | The code owner of each file in `.github/CODEOWNERS`. |
| `infra_ref` | the tag that Copier renders | Copier does not ask it and does not write it into `.copier-answers.yml`. The default is `_commit`, so the callers of the reusable workflows pin the tag that rendered them. |

## Files

| File | Content |
| --- | --- |
| `.copier-answers.yml` | The answers, the tag `_commit` and the source `_src_path`. `copier update` and Renovate read it. |
| `.github/renovate.json` | Extends `github>dan-petty/infra//renovate/base` ([renovate/README.md](../renovate/README.md)). |
| `.github/labels.yml` | The labels of the repository only: one `scope/<scope>` label for each scope, and with the release flow the two `autorelease:` labels of release-please. The workflow labels come from devops-cli. |
| `.github/CODEOWNERS` | `* <code_owner>`: GitHub asks the code owner to review each pull request. |
| `.github/workflows/pr-title.yml` | Calls the reusable workflow `dan-petty/infra/.github/workflows/pr-title.yml@<infra_ref>`, which checks the pull request title. |
| `.github/workflows/release.yml` | With the release flow: calls the reusable workflow `dan-petty/infra/.github/workflows/release.yml@<infra_ref>` on each push to `main`. It gives the job token no permission and passes the secret `RELEASE_APP_PRIVATE_KEY` by name, with no `secrets: inherit`. The job of the reusable workflow runs in the environment `release`, which holds the credentials of the release App, and gets the value of the secret of the environment. |
| `release-please-config.json`, `.release-please-manifest.json` | With the release flow: the release type, the tag `vX.Y.Z` and the first release `v0.1.0`. |
| `version.txt` | With the release type `simple`: the version that release-please writes. |
| `.pre-commit-config.yaml` | The hooks of `pre-commit-hooks`: no commit on `main`, the syntax of the YAML, JSON and TOML files, no private key, no large file, no conflict marker, and LF line endings with no trailing whitespace. infra's Renovate updates `rev` in the template. |
| `github/repository.yaml` | The settings baseline ("Settings baseline"). |
| `openspec/config.yaml` | The OpenSpec config, with the schema `spec-driven`. The file tells devops-cli that the repository plans each roadmap item as an OpenSpec change. Its rules are those of the jobs of devops-cli, and its context holds no fact of the repository: a person writes the first line, which tells what the repository makes. |
| `.devops/project.toml` | The project profile of devops-cli, with no key: a new repository has no fact that the detection of devops-cli does not find. devops-cli owns its keys. |

A file that only one repository needs stays in that repository.

## Settings baseline

`github/repository.yaml` holds the settings of the repository on GitHub. `devops repos onboard`
applies it, and `devops repos onboard --all --plan` shows each difference. Each key is the request
body of one endpoint of the GitHub REST API, with the field names of that body:

| Key | Endpoint | Baseline |
| --- | --- | --- |
| `repository` | `PATCH /repos/{owner}/{repo}` | Squash is the only merge method. The squash commit gets the pull request title (`PR_TITLE`) and body (`PR_BODY`). Auto-merge, the update of a branch, and the delete of a branch after the merge are on. Secret scanning and its push protection are on. |
| `vulnerability_alerts` | `PUT` or `DELETE /repos/{owner}/{repo}/vulnerability-alerts` | On. Renovate opens the security updates. |
| `private_vulnerability_reporting` | `PUT` or `DELETE /repos/{owner}/{repo}/private-vulnerability-reporting` | On. |
| `immutable_releases` | `PUT` or `DELETE /repos/{owner}/{repo}/immutable-releases` | On: nobody can move or delete the tag of a published release. |
| `code_scanning_default_setup` | `PATCH /repos/{owner}/{repo}/code-scanning/default-setup` | CodeQL default setup, with the languages that GitHub finds. |
| `actions_workflow_permissions` | `PUT /repos/{owner}/{repo}/actions/permissions/workflow` | The job token can only read, and no workflow approves a pull request. |
| `rulesets` | `POST /repos/{owner}/{repo}/rulesets`, or `PUT` on the ruleset of the same name | The ruleset `main` on the default branch: no delete, no force push, a pull request with squash only, the CodeQL and Code Quality results, and the required checks. The list of required checks is empty: the command adds each check that reported on the template pull request (devops-cli#6773, decision D3). |
| `environments` | `PUT /repos/{owner}/{repo}/environments/{name}`, then its deployment branch policies, variables and secrets | With the release flow only: the environment `release`, to which only `main` deploys, with the variable `RELEASE_APP_CLIENT_ID` and the secret `RELEASE_APP_PRIVATE_KEY`. |

The file names each variable and secret, and holds no value: the command reads each value from its
config or its keyring. `github-repository.schema.json` is a JSON Schema of the file. Its field names
and allowed values come from the OpenAPI description of the GitHub REST API
([github/rest-api-description](https://github.com/github/rest-api-description)). It refuses each
field that it does not name, so a misspelled field fails. To add a setting, add its field to the
schema and to `github/repository.yaml.jinja` in the same pull request.

## Releases and updates

The template has no release of its own: each release tag `vX.Y.Z` of infra is a release of the
template (README.md, "Releases"). The copier manager of Renovate reads `_commit` of
`.copier-answers.yml` in each rendered repository, and proposes each new tag of infra. Its pull
request runs `copier update`, which renders the new tag with the answers of the file, so the
callers of the reusable workflows also get the new tag.

A change that a rendered repository cannot take with `copier update` and its answers is a breaking
change: for example, a question with no default, or a question with a new name. Write it with `!`
after the type, so the release gets the next major version ("Releases").

## Test

`tests/test-repository-template.sh` (CI job "Repository template") renders the template with
`copier copy --defaults --vcs-ref HEAD` and no `--trust` into a temporary folder, with each answer
set: the default answers (no release flow), and the release flow with each release type and two
scopes. `--vcs-ref HEAD` renders the working tree, also the changes that are not committed. Then it
checks the rendered files:

- the set of files of the answer set, and no file with the suffix `.jinja`,
- `actionlint` on the workflows, `yamllint --strict` with `.yamllint.yaml` on each YAML file,
  `tomllib` on `.devops/project.toml`, `pre-commit validate-config` on `.pre-commit-config.yaml`,
  and the schema `spec-driven` of `openspec/config.yaml`,
- `check-jsonschema`: `github/repository.yaml` with `github-repository.schema.json`, and the
  release-please files with the schemas of the release-please release of the test,
- the config validator of Renovate, in strict mode, on `.github/renovate.json`,
- the answers in the files: the scope labels, the release type, the environment `release`, the tag
  of infra in the callers (`infra_ref`, else `_commit`), the secret that the release caller passes
  by name, and the code owner,
- that infra holds each workflow that a caller calls as a reusable workflow (`on: workflow_call`),
  with each secret that the release caller passes. A release tag of infra then holds each workflow
  that the repositories rendered at that tag call,
- that Copier refuses a scope that is not a lowercase name, and the scope `main`.

```sh
mise exec -- tests/test-repository-template.sh
```

npx installs the Renovate release of the test, and `check-jsonschema` downloads the release-please
schemas from GitHub. Renovate updates both versions of the test.
