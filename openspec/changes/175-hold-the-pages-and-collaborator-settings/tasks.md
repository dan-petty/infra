# Tasks

## 1. Add the Pages and collaborator cases to the template test

Kind: other. Reads: `tests/test-repository-template.sh`, `copier.yml`, `templates/repository/github/repository.yaml.jinja`. Changes: `tests/test-repository-template.sh`.

- [ ] 1.1 Add the case `render pages pages=true collaborators=example-user:push` with `validate pages` and the `expect` lines for `.pages.build_type`, the environment `github-pages` and the collaborator, and the refusal case for `collaborators=example-user:owner`, to `tests/test-repository-template.sh`; the case fails on the base, which holds no `pages` answer and no `pages` key
  - Verification: `$ uv run devops ci --check --only template` passes

## 2. Name the Pages site and the collaborators in the settings schema

Kind: other. Reads: `templates/github-repository.schema.json`, `templates/repository/github/repository.yaml.jinja`. Changes: `templates/github-repository.schema.json`.

- [ ] 2.1 Add the `pages` property and the `collaborators` array, with the `collaborator` definition of `username` and `permission`, to `templates/github-repository.schema.json`; keep `additionalProperties: false` on each object, and require `build_type` of `pages`
  - Verification: `$ uv run devops ci --check --only template` passes

## 3. Ask for the Pages site and the collaborators

Kind: other. Reads: `copier.yml`, `templates/README.md`. Changes: `copier.yml`.

- [ ] 3.1 Add the `pages` answer of type bool with default false and the `collaborators` answer of type str with default empty to `copier.yml`, with the validator that refuses a value that is not a username with the permission `pull`, `triage`, `push`, `maintain` or `admin`
  - Verification: `$ uv run devops ci --check --only template` passes

## 4. Render the site, the collaborators and the github-pages environment

Kind: other. Reads: `templates/repository/github/repository.yaml.jinja`, `copier.yml`, `templates/github-repository.schema.json`. Changes: `templates/repository/github/repository.yaml.jinja`.

- [ ] 4.1 In `templates/repository/github/repository.yaml.jinja`, render the `pages` key with `build_type: workflow` when the `pages` answer is true, render each `username:permission` pair of the `collaborators` answer as an item of `collaborators`, and render the environment `github-pages` with the branch policy `main`; render `environments` when `release_flow` or `pages` is true, and rewrite the comment of that block for both environments
  - Verification: `$ uv run devops ci --check --only template` passes

## 5. Describe the two answers and the two keys in the template README

Kind: other. Reads: `templates/README.md`, `copier.yml`, `templates/github-repository.schema.json`. Changes: `templates/README.md`.

- [ ] 5.1 Add the rows `pages` and `collaborators` to the question table of `templates/README.md`, and the rows `pages` and `collaborators` to the settings table, with the environment `github-pages` and the permission of each collaborator
  - Verification: `$ uv run devops ci docs` passes
- [ ] 5.2 Edit `templates/README.md`
  - Verification: `$ uv run devops ci docs` passes
