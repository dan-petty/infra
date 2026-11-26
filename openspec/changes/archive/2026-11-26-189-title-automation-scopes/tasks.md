# Tasks

## 1. Behavior

- [x] 1.1 Change the cases of `tests/test-pr-title-scopes.sh` to expect the scopes of every repository, which fail on the base
  - Verification: `$ mise exec -- tests/test-pr-title-scopes.sh`
- [x] 1.2 Print `ci`, `deps`, `docs`, `main` and `spec` in `scripts/pr-title-scopes.sh`
  - Verification: `$ mise exec -- tests/test-pr-title-scopes.sh`

## 2. Documents

- [x] 2.1 Describe the list in `README.md` and in the comments of the workflows and of the labels template
  - Verification: `$ mise exec -- actionlint`
- [x] 2.2 Keep the rendered repository template passing
  - Verification: `$ mise exec -- tests/test-repository-template.sh`

## 3. Titles of image updates

- [x] 3.1 Name an image with a registry host by the last two parts of its reference in `renovate/base.json`, and describe it in `renovate/README.md`
  - Verification: `$ mise exec -- tests/test-renovate-presets.sh`
- [x] 3.2 Check that the summaries of the long image updates have at most 60 characters
  - Verification: give the updates to `flattenUpdates` and `generateBranchConfig` of Renovate with `renovate/base.json`, and count the characters after `chore(deps): `

## 4. Scopes of infra

- [x] 4.1 Declare `scope/security`, `scope/terraform`, `scope/templates` and `scope/tools` in `.github/labels.yml`
  - Verification: `$ mise exec -- scripts/pr-title-scopes.sh .github/labels.yml`
