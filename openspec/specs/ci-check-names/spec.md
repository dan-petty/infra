# ci-check-names Specification

## Purpose

The checks of `ci.yml` that a ruleset can require keep one name, whether their work runs or is skipped.

## Requirements

### Requirement: A conditional reusable workflow call reports one check name
For each job of `.github/workflows/ci.yml` that has a condition and calls a reusable workflow, another job SHALL need it, run with `if: always()`, and report a check with one name. That job SHALL fail when the call or the job `changes` ends with a result other than success or skipped.

#### Scenario: The validation runs
- **WHEN** a pull request changes the Kubernetes files and the validation succeeds
- **THEN** the check `K8s` reports success

#### Scenario: The validation is skipped
- **WHEN** a pull request changes no Kubernetes file
- **THEN** the check `K8s` reports success

#### Scenario: The validation fails or is cancelled
- **WHEN** the validation or the job `changes` fails or is cancelled
- **THEN** the check `K8s` fails

#### Scenario: A call with no reporting job
- **WHEN** `mise exec -- tests/test-ci-check-names.sh` reads a conditional call that no job with `if: always()` needs
- **THEN** it exits non-zero and names the job
