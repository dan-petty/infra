# Tasks

## 1. Template callers (behavior)

- [x] 1.1 Write the failing test: each rendered caller of infra pins a 40-character commit SHA with the comment `# <tag>`, a render of a lightweight tag pins `git rev-parse <tag>^{commit}`, and a `copier update` after Renovate moved the callers gives no conflict
  - Verification: `$ mise exec -- tests/test-repository-template.sh` (on the base, 85 of 95 cases pass)
- [x] 1.2 Render each caller in `pr-title.yml.jinja` and `release.yml.jinja` as `@{{ _copier_conf.vcs_ref_hash }} # {{ infra_ref }}`, and delete the test case `commit` that expected a bare `_commit`
  - Verification: `$ mise exec -- tests/test-repository-template.sh`
- [x] 1.3 Write the failing test: a render of a template folder with no git fails with the message "Copier gives no commit of the template", then guard each caller with the filter `mandatory`
  - Verification: `$ mise exec -- tests/test-repository-template.sh` (before the guard, 95 of 96 cases pass)
- [x] 1.4 Check a render of a release tag with actionlint and zizmor
  - Verification: in a clone of infra, tag the commit of this change as `v0.25.1` (lightweight), run `copier copy --defaults --vcs-ref v0.25.1 --data release_flow=true <clone> <dir>`, then `mise exec -- actionlint <dir>/.github/workflows/*.yml` and `.venv/bin/zizmor --offline <dir>/.github/workflows/`: no error and no finding. Each caller holds `git rev-parse v0.25.1^{commit}`.

## 2. Renovate fixture

- [x] 2.1 Hold the form `@<sha> # v0.1.0` in `tests/renovate/.github/workflows/k8s.yml`, and check that the github-actions manager reads it as a digest pin with the tag
  - Verification: `$ mise exec -- tests/test-renovate-presets.sh`
- [x] 2.2 Simulate the first update of a repository that Renovate pinned at `v0.24.3`
  - Verification: render the tag `v0.24.2` of a clone of infra, set the caller to `@3d43c9f2d4a167e5f6600dff0c5ba60c3ba127d6 # v0.24.3` and commit, then run `copier update --skip-answered --defaults --vcs-ref v0.25.1`: the caller holds conflict markers. Set the caller to the commit of `v0.25.1` before the update: no conflict.

## 3. Documents

- [x] 3.1 State the form in `README.md`, `templates/README.md`, the comment of `infra_ref` in `copier.yml` and the comments of the reusable workflows
  - Verification: `$ .venv/bin/yamllint --strict .`
  - Verification: `$ .venv/bin/zizmor --offline .github/workflows/`
  - Verification: `$ mise exec -- actionlint`
- [x] 3.2 Keep the private-data guard passing
  - Verification: `$ mise exec -- tests/test-private-data-scan.sh`
  - Verification: `$ mise exec -- scripts/private-data-scan.sh dir .`

## Workflow follow-up

- The copier dependency out of the group `infra` of `renovate/k8s.json`, and the catch-up `copier update` in dan-petty/homelab and dan-petty/danielpetty.com: #216.
- The new render of `.github/workflows/pr-title.yml` in the template pull request dan-petty/vibes#314, at the release that holds this change.
