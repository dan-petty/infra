# Proposal: the template pins each infra workflow caller to a commit SHA

## Why

The repository template renders each caller of a reusable workflow of infra with a bare tag, `uses: dan-petty/infra/.github/workflows/pr-title.yml@vX.Y.Z` (#214). This causes two defects in each repository that gets the template:

- Two Renovate managers write the same line. The github-actions manager pins a digest (`pinDigests` of `renovate/base.json`) and writes `@<sha> # vX.Y.Z`. The copier manager renders `@vX.Y.Z`. In dan-petty/dotfiles, #13 and #17 pinned the line, and the copier update #18 then committed conflict markers on it.
- A repository with a supply-chain rule refuses the tag. The rule `mutable_action_ref` of dan-petty/vibes fails the template pull request dan-petty/vibes#314 at `.github/workflows/pr-title.yml`.

## What Changes

- `pr-title.yml.jinja` and `release.yml.jinja` render each caller as `@{{ _copier_conf.vcs_ref_hash }} # {{ infra_ref }}`: the commit that Copier renders, with the tag in a comment. A render of a template folder with no git fails with a message, and writes no `@None`.
- `tests/test-repository-template.sh` checks the form in each render, renders a lightweight tag of a git repository that holds the template, runs a `copier update` after Renovate moved the callers, and renders a template folder with no git. Its case `commit`, which expected a bare `_commit`, goes: the tag case replaces it.
- The Renovate fixture `tests/renovate/.github/workflows/k8s.yml` holds the same form, and `tests/test-renovate-presets.sh` checks that the github-actions manager reads it as a digest pin with the tag.
- `README.md` ("Pin a release", "Call the reusable workflows" and the three examples), `templates/README.md`, the comment of `infra_ref` in `copier.yml` and the comments of the reusable workflows state the form.
- The behavior that a consumer sees changes, so the change has the spec delta `template-workflow-pins`.

## Capabilities

- `template-workflow-pins` (new): the pin of each caller of a reusable workflow of infra that the repository template renders.

## Impact

A repository gets the form with the `copier update` to the release that holds this change. A repository whose caller Renovate already pinned to an older release, such as `@3d43c9f… # v0.24.3` with `_commit: v0.24.2`, gets a conflict at that first update when the copier pull request runs first. Where the copier manager has its own branch (dan-petty/dotfiles, dan-petty/devcontainer-features), the github-actions pull request of the same release writes the same line, and the copier pull request then updates with no conflict. dan-petty/homelab and dan-petty/danielpetty.com also extend `renovate/k8s`, whose group `infra` puts the copier update into the branch of the other pins, where `copier update` stops ("Destination repository is dirty"). Their `_commit` stays `v0.24.1` until #216 gives the copier dependency its own branch and runs a manual `copier update` (design, "Renovate"). The change fits one pull request.

## Feasibility

Confirmed on 2026-11-27 against the source of the pinned tools and the git data of infra:

- Copier 9.19.1 (`pyproject.toml`): `_copier_conf.vcs_ref_hash` is `self.template.commit_hash` (`copier/_main.py:455`), which is `git rev-parse HEAD` of the template checkout, else `None` when the template is not a git repository (`copier/_template.py:304-308`). A render of `HEAD` with changes that are not committed gets the commit that Copier makes of them (`copier/_vcs.py:421-443`).
- `git cat-file -t` gives `commit` for `v0.24.1`, `v0.24.3` and `v0.25.0`: the tags of infra are lightweight. `git rev-parse v0.24.3^{commit}` is `3d43c9f2d4a167e5f6600dff0c5ba60c3ba127d6`, the digest that Renovate wrote in dotfiles#17.
- The github-tags datasource of Renovate 45.1.0 gives the commit as the digest of a lightweight tag and of an annotated tag (`util/github/graphql/query-adapters/tags-query-adapter.js:65-78`). A render of an annotated tag `v2.0.0` pins its commit `339e3b3…`, not the tag object `e9ca8a6…`.
- Copier 9.19.1 validates an answer only from `--data` or a prompt; under `--defaults` a question with `when: false` takes its default with no validation (`copier/_main.py:636-670`). Copier loads `jinja2_ansible_filters` by default, and its filter `mandatory` raises its message for an undefined value (`jinja2_ansible_filters/core_filters.py:293-304`).
- Renovate 45.1.0 (the release of the tests), `modules/manager/github-actions/extract.js`: a reusable workflow gets `depType: workflow` (line 61); a 40-character ref is `currentDigest` and the comment is `currentValue` (lines 74-76); an update writes `<depName>/<path>@{{newDigest}} # {{newValue}}` (line 63).
- Copier 9.19.1 `copier update` applies the diff of the old and the new render with `git apply --reject`, and runs `git merge-file` on each rejected file (`copier/_main.py:1577-1645`). The same change on two sides merges with no conflict.
- A render of a lightweight tag `v0.25.1` on the commit of this change pins `59e2a41de1c2d65034b5f9341d7a573c48092e13`, the output of `git rev-parse v0.25.1^{commit}`. actionlint passes. zizmor 1.33.1 `--offline` reports no finding; on the render of `v0.25.0` it reports 2 high `unpinned-uses` findings. The function `check_action_pinning` of the vibes `tools/supply_chain_audit.py` gives no finding for the new render and `mutable_action_ref` for each caller of the `v0.25.0` render.
- On the base, the new template test passes 85 of 95 cases: each caller holds a bare tag, and the `copier update` writes conflict markers into both callers. With the change, it passes 95 of 95 cases. The case of a template folder with no git fails before the guard (`@None # `) and passes after it: 96 of 96 cases.

## Existing Tool Considered

Copier (`_copier_conf.vcs_ref_hash`) and the github-actions manager of Renovate (digest pins) cover the need, and both are in use. The change adds no tool and no script, so it has no build, upkeep or fix cost. It deletes the test case `commit` of `tests/test-repository-template.sh`, which the render of a tag replaces.
