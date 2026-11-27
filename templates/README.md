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
| `scope_descriptions` | `{}` | The description of a `scope/<scope>` label, by scope, as a YAML mapping, such as `{api: "The HTTP API in api/"}`. A scope with no description gets "The area `<scope>` of this repository", and `ci`, `deps` and `docs` get the description of the template. Copier refuses a scope that is not `ci`, `deps`, `docs` or a scope of `scopes`, and a description that is not a text of 1 to 100 characters with no `"` or `\`. |
| `required_checks` | empty | The checks of the workflows of the repository that each pull request into `main` must pass, separated by commas, such as `K8s,Lint`. The ruleset `main` of `github/repository.yaml` requires each of them and the title check `PR title / Semantic PR title` of `.github/workflows/pr-title.yml`, from GitHub Actions (integration `15368`). Copier refuses a name with a character other than a letter, a digit, a space or `._/()-`. |
| `code_coverage` | `false` | Gate pull requests with a `code_coverage` rule in the ruleset `main` of `github/repository.yaml`, with `minimum_coverage: 80`. The default is `false`. Answer `true` for a repository that reports coverage. |
| `infra_ref` | the tag that Copier renders | Copier does not ask it and does not write it into `.copier-answers.yml`. The default is `_commit`, the tag in the comment of each caller of a reusable workflow. The caller pins `_copier_conf.vcs_ref_hash`, the commit of that tag ("Files"). |

## Files

| File | Content |
| --- | --- |
| `.copier-answers.yml` | The answers, the tag `_commit` and the source `_src_path`. `copier update` and Renovate read it. |
| `.github/renovate.json` | Extends `github>dan-petty/infra//renovate/base` ([renovate/README.md](../renovate/README.md)). The repository owns it after the first copy ("Owners"). |
| `.github/labels.yml` | The labels of the repository only: one gray `scope/<scope>` label for each scope, with its description of `scope_descriptions`, and with the release flow the two `autorelease:` labels of release-please. The workflow labels come from devops-cli. |
| `.github/CODEOWNERS` | `* <code_owner>`: GitHub asks the code owner to review each pull request. |
| `.github/workflows/pr-title.yml` | Calls the reusable workflow `dan-petty/infra/.github/workflows/pr-title.yml@<sha> # <infra_ref>`, which checks the pull request title. `<sha>` is the commit that Copier renders (`_copier_conf.vcs_ref_hash`), the commit of the tag `<infra_ref>`. |
| `.github/workflows/release.yml` | With the release flow: calls the reusable workflow `dan-petty/infra/.github/workflows/release.yml@<sha> # <infra_ref>` on each push to `main`. It gives the job token no permission and passes the secret `RELEASE_APP_PRIVATE_KEY` by name, with no `secrets: inherit`. The job of the reusable workflow runs in the environment `release`, which holds the credentials of the release App, and gets the value of the secret of the environment. |
| `release-please-config.json`, `.release-please-manifest.json` | With the release flow: the release type, the tag `vX.Y.Z` and the first release `v0.1.0`. |
| `version.txt` | With the release type `simple`: the version that release-please writes. |
| `.pre-commit-config.yaml` | The hooks of `pre-commit-hooks`: no commit on `main`, the syntax of the YAML, JSON and TOML files, no private key, no large file, no conflict marker, and LF line endings with no trailing whitespace. infra's Renovate updates `rev` in the template. |
| `github/repository.yaml` | The settings baseline ("Settings baseline"). |
| `openspec/config.yaml` | The OpenSpec config, with the schema `spec-driven`. The file tells devops-cli that the repository plans each roadmap item as an OpenSpec change. Its rules are those of the jobs of devops-cli, and its context holds no fact of the repository: a person writes the first line, which tells what the repository makes. |
| `.devops/project.toml` | The project profile of devops-cli, with no key: a new repository has no fact that the detection of devops-cli does not find. devops-cli owns its keys. |

A file that only one repository needs stays in that repository.

## Owners

Each file has one owner (#225), so `copier update` has no second change to merge:

- The template owns each file of the table above, except the files of the next item. `copier
  update` and `copier recopy` write it again from the answers of `.copier-answers.yml`. Change such
  a file in the template, or change an answer with `copier update --data <question>=<answer>`:
  a scope in `scopes`, its label description in `scope_descriptions`, a required check in
  `required_checks`. Renovate leaves the pins of the
  callers `.github/workflows/pr-title.yml` and `.github/workflows/release.yml` to the copier update
  (a package rule of [renovate/base.json](../renovate/base.json)).
- The repository owns the files of `_skip_if_exists` of `copier.yml` after the first copy:
  `.github/renovate.json`, `.pre-commit-config.yaml` and `.devops/project.toml` hold its own rules,
  and release-please writes `version.txt` and `.release-please-manifest.json`. Copier writes such a
  file only when the repository does not hold it, also on `copier update` and `copier recopy
  --overwrite` (Copier 9.19.1).

A repository with changed template files re-adopts the template once, with the answers that keep
its content:

```sh
copier recopy --skip-answered --defaults --overwrite --vcs-ref vX.Y.Z --data-file answers.yml .
```

`answers.yml` holds `scopes`, `scope_descriptions` and `required_checks` with the values of the
labels and the required checks of the repository.

`copier recopy` renders the tag over the repository with no 3-way merge, so the result has no
conflict. It keeps each file of `_skip_if_exists`. Then Renovate gives each new release with
`copier update`.

infra is the template source, not a render of it: it has no `.copier-answers.yml`, and a person
keeps its own copies of the template files.

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
| `rulesets` | `POST /repos/{owner}/{repo}/rulesets`, or `PUT` on the ruleset of the same name | The ruleset `main` on the default branch: no delete, no force push, a pull request with squash only, the CodeQL and Code Quality results, with `code_coverage=true` the `code_coverage` rule (`minimum_coverage: 80`), and the required checks: each check of `required_checks` and the title check `PR title / Semantic PR title`, from GitHub Actions (integration `15368`). The command also adds each check that reported on the template pull request (devops-cli#6773, decision D3). |
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
`.copier-answers.yml` in each rendered repository, and proposes the newest tag of infra. Its pull
request runs `copier update --skip-answered --defaults`, which renders the new tag with the answers
of the file, so the callers of the reusable workflows also get the commit of the new tag, with the
new tag in the comment.

The copier update has one branch in each repository: a package rule of `renovate/base.json` sets
`separateMajorMinor: false` and `separateMinorPatch: false` for the copier manager, so Renovate
proposes only the newest tag, never a patch and a minor update in two branches that change the same
files. The copier update also has a branch of its own, out of the group `infra` of
`renovate/k8s.json` (#216): `copier update` runs only on a clean branch.

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
- the answers in the files: the scope labels, the release type, the environment `release`, the
  secret that the release caller passes by name, the code owner, the description of each scope
  label, and the required checks: each check of `required_checks` and the title check, which is
  the name of the job of the caller and the name of the job of `pr-title.yml` of infra,
- each caller of a reusable workflow of infra: a commit SHA of 40 characters, with the tag of infra
  (`infra_ref`, else `_commit`) in a comment, and no bare tag,
- a render of a lightweight tag of a git repository that holds the template: each caller pins
  `git rev-parse <tag>^{commit}`. Then the repository writes its own content into each file of
  `_skip_if_exists`, and the next tag changes each file of the template. `copier update
  --skip-answered --defaults` (as Renovate runs it), and `copier recopy --overwrite` over a copy
  with changed template files and callers that Renovate moved, give no conflict, keep each file of
  `_skip_if_exists`, and give each other file the render of the next tag ("Owners"),
- that a render of a template folder with no git fails with the message "Copier gives no commit of
  the template", so no caller gets `@None`,
- that infra holds each workflow that a caller calls as a reusable workflow (`on: workflow_call`),
  with each secret that the release caller passes. A release tag of infra then holds each workflow
  that the repositories rendered at that tag call,
- that Copier refuses a scope that is not a lowercase name, the scope `main`, a check name that is
  not plain YAML text, a description of an unknown scope, and a description that is not a text of
  1 to 100 characters with no `"` or `\`.

```sh
mise exec -- tests/test-repository-template.sh
```

npx installs the Renovate release of the test, and `check-jsonschema` downloads the release-please
schemas from GitHub. Renovate updates both versions of the test.
