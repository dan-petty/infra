## Purpose

The owner of each file of the repository template of infra, so that `copier update` and `copier recopy` give no conflict and keep the content of the repository, and the required checks that a repository holds as an answer.

## ADDED Requirements

### Requirement: Each file of the template has one owner
The template SHALL own each file that it renders, except `.github/renovate.json`, `.pre-commit-config.yaml`, `.devops/project.toml`, `version.txt` and `.release-please-manifest.json`, which the repository owns after the first copy (`_skip_if_exists` of `copier.yml`). `copier update` and `copier recopy --overwrite` SHALL give each file of the template the render of the target tag, keep each file of the repository as it is, and write no conflict marker and no rejected hunk.

#### Scenario: A copier update of a repository with its own content
- **WHEN** a render of `v1.0.0` holds its own content in the five files of the repository, the tag `v1.1.0` changes each file of the template, and `copier update --skip-answered --defaults --vcs-ref v1.1.0` runs
- **THEN** `mise exec -- tests/test-repository-template.sh` finds no conflict, no change in the five files, each other file equal to a render of `v1.1.0`, and each caller pinned to the commit of `v1.1.0`

#### Scenario: The re-adoption of a repository with changed template files
- **WHEN** the same repository also holds a label, a comment and caller pins of another release that the template does not render, and `copier recopy --skip-answered --defaults --overwrite --vcs-ref v1.1.0` runs
- **THEN** `mise exec -- tests/test-repository-template.sh` finds no conflict, no change in the five files, and each other file equal to a render of `v1.1.0`

### Requirement: The required checks are an answer
The ruleset `main` of `github/repository.yaml` SHALL require each check of the answer `required_checks`, once, and then the title check of `.github/workflows/pr-title.yml`, each with the integration 15368 of GitHub Actions. Copier SHALL refuse a check name with a character other than a letter, a digit, a space or `._/()-`.

#### Scenario: The default answers require the title check
- **WHEN** Copier renders the working tree with the default answers
- **THEN** `mise exec -- tests/test-repository-template.sh` finds one required check, named by the job of the caller and the job of `pr-title.yml` of infra, and `check-jsonschema` accepts `github/repository.yaml`

#### Scenario: The answer adds checks
- **WHEN** Copier renders the working tree with `required_checks=K8s, Lint / yamllint,K8s`
- **THEN** `mise exec -- tests/test-repository-template.sh` finds the required checks `K8s`, `Lint / yamllint` and the title check, each from integration 15368

#### Scenario: Copier refuses a check name that is not plain
- **WHEN** Copier renders the working tree with `required_checks=K8s: lint`
- **THEN** `copier copy` fails, and `mise exec -- tests/test-repository-template.sh` reports the refusal
