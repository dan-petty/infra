# Tasks

## 1. Behavior

- [x] 1.1 Write `tests/test-ci-check-names.sh`, which fails on the base
  - Verification: `$ mise exec -- tests/test-ci-check-names.sh`
- [x] 1.2 Add the job `k8s` that reports the check, and rename the call to `k8s-validate`
  - Verification: `$ mise exec -- tests/test-ci-check-names.sh`

## 2. Documents

- [x] 2.1 Name the check and the test in `README.md`, Checks
  - Verification: `$ mise exec -- actionlint`
