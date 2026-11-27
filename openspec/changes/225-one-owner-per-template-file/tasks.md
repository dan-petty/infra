# Tasks

## 1. The owners of the template files

Kind: behavior.

- [x] 1.1 Add the cases to `tests/test-repository-template.sh`: a repository writes its own content into the five files, the next tag changes each template file, and `copier update` and `copier recopy --overwrite` give no conflict, keep the five files and render each other file; the required checks of the default answers and of `required_checks`; the refusal of a check name that is not plain. See them fail on `main`
  - Verification: `$ mise exec -- tests/test-repository-template.sh`
- [x] 1.2 Add `_skip_if_exists` and the answer `required_checks` to `copier.yml`, and render the required checks in `templates/repository/github/repository.yaml.jinja`
  - Verification: `$ mise exec -- tests/test-repository-template.sh`

## 2. The Renovate rules of the copier update

Kind: behavior.

- [x] 2.1 Add the cases to `tests/test-renovate-presets.sh` and the fixture: Renovate leaves each caller of the template to the copier update, the copier update has one branch, and the lookup cases of both. See the offline cases fail on `main`
  - Verification: `$ mise exec -- tests/test-renovate-presets.sh`
- [x] 2.2 Add the two package rules to `renovate/base.json`
  - Verification: `$ mise exec -- tests/test-renovate-presets.sh`
- [x] 2.3 Check the copier update of the fixture with a lookup, as in `## Feasibility` of the proposal
  - Verification: `renovate --platform=local --dry-run=lookup` of Renovate 45.1.0 gives the copier dependency at `v0.24.1` one update, in the bucket `latest`

## 3. infra is the template source

Kind: other.

- [x] 3.1 Remove `.copier-answers.yml` of infra
  - Verification: `git ls-files .copier-answers.yml` prints nothing

## 4. Documents

Kind: other.

- [x] 4.1 Describe the owners in `templates/README.md` ("Owners", "Releases and updates", "Test", the question and settings tables), the Copier update in `renovate/README.md`, and the template callers in README.md, "Pin a release"; name the answer to change in the template files that hold answers
  - Verification: read the sections; `.venv/bin/yamllint --strict .` and `mise exec -- scripts/private-data-scan.sh dir .` exit 0

## Workflow follow-up

- After the release that holds this change, each consumer with `.copier-answers.yml` runs `copier recopy --skip-answered --defaults --overwrite --vcs-ref <release>` with its answers, in one pull request of its own.
- #224 has no cause after the merge, and closes.
