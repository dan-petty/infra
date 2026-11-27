# Design

## Decisions

- **Render `@{{ _copier_conf.vcs_ref_hash }} # {{ infra_ref }}` in each caller.**: Copier gives the commit of the template checkout in `_copier_conf.vcs_ref_hash` (`copier/_main.py:455`). The tags of infra are lightweight, so this commit is the digest that the github-actions manager reads for the tag. Renovate writes `@{{newDigest}} # {{newValue}}` (`extract.js:63`), so both managers write the same text for one release.
- **Keep `infra_ref` as the tag of the comment.**: Its default stays `_commit`, and the test still gives it, because a render of `HEAD` gets the output of `git describe`. The SHA comes from the same render, so the SHA and the tag of a release render always agree.
- **Add no Renovate rule.**: The github-actions manager reads the rendered line as a digest pin with the tag (`depType: workflow`, `currentDigest`, `currentValue`; `tests/test-renovate-presets.sh`). The pull request that merges second makes no conflict: Git merges the same change on two sides, and `copier update` keeps a caller that Renovate already moved (`tests/test-repository-template.sh`). The github-actions pull request also heals the first update of a repository that Renovate pinned to an older release ("Renovate").
- **Write the same form in the hand-written examples of `README.md`.**: The preset pins a digest for each github-actions dependency, so Renovate writes this form into a tag pin. zizmor, with its default policy, refuses a tag pin of an action that is not of `actions/` or `github/`.
- **Render a tag of a git repository in the test.**: The test copies `copier.yml` and `templates/` of the working tree into a new git repository with two lightweight tags, so it proves the working tree that is not committed, also in a pre-commit run. Its commits set the user, turn off signing and hooks, and need no git configuration of the runner.

## Renovate

The first `copier update` to the release that holds this change, in a repository with `_commit: v0.24.2` and the Renovate line `@3d43c9f… # v0.24.3`, was simulated with the tags of infra and a local lightweight tag `v0.25.1` on the commit of this change:

- The caller still at `# v0.24.3`: `git merge-file` writes conflict markers, because the old render `@v0.24.2`, the line of the repository and the new render are three different lines.
- The caller that the github-actions manager moved to `@59e2a41… # v0.25.1` first: the update has no conflict.

Both managers propose the release in the same run. When the copier pull request holds the markers, it does not merge. The github-actions pull request merges after its checks pass, the copier branch then conflicts with `main`, and Renovate (`rebaseWhen: conflicted`) runs `copier update` again on the new `main` with no conflict. dan-petty/homelab, dan-petty/danielpetty.com, dan-petty/devcontainer-features and dan-petty/dotfiles hold the line `# v0.24.3` today (2026-11-27).

The cost of the two managers is one more pull request for each release of infra in each rendered repository. That pull request merges with the same change as the other, or Renovate closes it when the dependency is current.

## Rejected alternatives

- **Keep the tag, and turn off the github-actions manager for the callers.**: The tag stays mutable. The rule `mutable_action_ref` of dan-petty/vibes refuses it, and zizmor 1.33.1 `--offline` reports 2 high `unpinned-uses` findings on the render of `v0.25.0`. The release `v0.24.1` has `immutable: false`.
- **A rule in `renovate/base.json` that turns off the github-actions manager for `dan-petty/infra` in `.github/workflows/pr-title.yml` and `release.yml`.**: A preset rule applies to each repository at once. The four repositories with the line `# v0.24.3` then get conflict markers at their first update, and no other pull request moves the line to heal it (simulation above). A rule on file names also stops the updates of a hand-written caller with the same name in a repository with no template. A code search of the owner on 2026-11-27 found no such caller today, so the rule gives no gain now.
- **The same rule in the template file `.github/renovate.json`.**: dan-petty/homelab and dan-petty/danielpetty.com changed this file: they extend `renovate/k8s` and have 8 and 1 `packageRules`. A new block in the template file then conflicts at their `copier update`, as other hand edits of template files did in dotfiles#18 and devcontainer-features#26.
- **A hidden question `infra_sha` with the default `{{ _copier_conf.vcs_ref_hash }}`.**: No caller gives another SHA, and a separate answer lets the SHA and the tag of the comment disagree. The template uses the value of the render.
- **Get the SHA in a `_tasks` command or in `devops repos onboard`.**: The template has no `_tasks`, so Copier runs it without `--trust`. The copier manager of Renovate runs `copier update`, not `devops repos onboard`, so the SHA of the next release would not change.

## Risks

- The form depends on lightweight tags. release-please creates each tag of infra through the GitHub release API, which makes a lightweight tag. With an annotated tag, `vcs_ref_hash` is still the commit, and the test fixes the lightweight form that infra uses.
- A render from a folder that is not a git repository gives `None` for `vcs_ref_hash`. Each consumer renders the HTTPS URL of infra, and the test renders git repositories only. actionlint 1.7.12 accepts `@None`, but zizmor 1.33.1 reports `unpinned-uses` for it, and the check `pinned` of the template test refuses it.
