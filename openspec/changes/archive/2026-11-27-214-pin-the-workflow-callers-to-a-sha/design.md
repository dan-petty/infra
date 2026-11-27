# Design

## Decisions

- **Render `@{{ _copier_conf.vcs_ref_hash }} # {{ infra_ref }}` in each caller.**: Copier gives the commit of the template checkout in `_copier_conf.vcs_ref_hash` (`copier/_main.py:455`). This commit is the digest that the github-actions manager reads for the tag: the github-tags datasource gives the commit for a lightweight tag and for an annotated tag (`util/github/graphql/query-adapters/tags-query-adapter.js:65-78`). Renovate writes `@{{newDigest}} # {{newValue}}` (`extract.js:63`), so both managers write the same text for one release.
- **Keep `infra_ref` as the tag of the comment.**: Its default stays `_commit`, and the test still gives it, because a render of `HEAD` gets the output of `git describe`. The SHA comes from the same render, so the SHA and the tag of a release render always agree.
- **Add no Renovate rule for the callers.**: The github-actions manager reads the rendered line as a digest pin with the tag (`depType: workflow`, `currentDigest`, `currentValue`; `tests/test-renovate-presets.sh`). The pull request that merges second makes no conflict: Git merges the same change on two sides, and `copier update` keeps a caller that Renovate already moved (`tests/test-repository-template.sh`). In a repository where the copier manager has its own branch, the github-actions pull request also heals the first update after an older Renovate pin ("Renovate"). The group `infra` of `renovate/k8s.json` is a separate defect: #216.
- **Write the same form in the hand-written examples of `README.md`.**: The preset pins a digest for each github-actions dependency, so Renovate writes this form into a tag pin. zizmor, with its default policy, refuses a tag pin of an action that is not of `actions/` or `github/`.
- **Render a tag of a git repository in the test.**: The test copies `copier.yml` and `templates/` of the working tree into a new git repository with two lightweight tags, so it proves the working tree that is not committed, also in a pre-commit run. Its commits set the user, turn off signing and hooks, and need no git configuration of the runner.

## Renovate

The first `copier update` to the release that holds this change, in a repository with `_commit: v0.24.2` and the Renovate line `@3d43c9f… # v0.24.3`, was simulated with the tags of infra and a local lightweight tag `v0.25.1` on the commit of this change:

- The caller still at `# v0.24.3`: `git merge-file` writes conflict markers, because the old render `@v0.24.2`, the line of the repository and the new render are three different lines.
- The caller that the github-actions manager moved to `@59e2a41… # v0.25.1` first: the update has no conflict.

dan-petty/homelab, dan-petty/danielpetty.com, dan-petty/devcontainer-features and dan-petty/dotfiles hold the line `# v0.24.3` today (2026-11-27). Their path to the release depends on the presets that they extend:

- dan-petty/dotfiles and dan-petty/devcontainer-features extend only `renovate/base`, so the copier manager has its own branch (dotfiles#18, `renovate/https-github.com-dan-petty-infra.git-0.24.x`). Both managers propose the release in the same run. When the copier pull request holds the markers, it does not merge. The github-actions pull request merges after its checks pass, the copier branch then conflicts with `main`, and Renovate (`rebaseWhen: conflicted`) runs `copier update` again on the new `main` with no conflict.
- dan-petty/homelab and dan-petty/danielpetty.com also extend `renovate/k8s`. Its group `infra` (`renovate/k8s.json:44-46`) matches the copier dependency `https://github.com/dan-petty/infra.git` too, so Renovate puts the copier update into the branch `renovate/patch-infra` with the other pins. `copier update` stops there with "Destination repository is dirty" (artifact error on danielpetty.com#105 and homelab#392), and danielpetty.com#107 and homelab#409 changed only the pins. `_commit` is `v0.24.1` in both. The group branch moves the callers to the release, but the template files do not change. These two repositories need a manual `copier update --skip-answered --defaults --vcs-ref <release>`, and the copier dependency needs its own branch: #216.

The cost of the two managers is one more pull request for each release of infra in each rendered repository. That pull request merges with the same change as the other, or Renovate closes it when the dependency is current.

## Rejected alternatives

- **Keep the tag, and turn off the github-actions manager for the callers.**: The tag stays mutable. The rule `mutable_action_ref` of dan-petty/vibes refuses it, and zizmor 1.33.1 `--offline` reports 2 high `unpinned-uses` findings on the render of `v0.25.0`. The release `v0.24.1` has `immutable: false`.
- **A rule in `renovate/base.json` that turns off the github-actions manager for `dan-petty/infra` in `.github/workflows/pr-title.yml` and `release.yml`.**: A preset rule applies to each repository at once. dotfiles and devcontainer-features, with the line `# v0.24.3`, then get conflict markers at their first update, and no other pull request moves the line to heal it (simulation above). A rule on file names also stops the updates of a hand-written caller with the same name in a repository with no template. A code search of the owner on 2026-11-27 found no such caller today, so the rule gives no gain now.
- **The same rule in the template file `.github/renovate.json`.**: dan-petty/homelab and dan-petty/danielpetty.com changed this file: they extend `renovate/k8s` and have 8 and 1 `packageRules`. A new block in the template file then conflicts at their `copier update`, as other hand edits of template files did in dotfiles#18 and devcontainer-features#26.
- **A hidden question `infra_sha` with the default `{{ _copier_conf.vcs_ref_hash }}`.**: No caller gives another SHA, and a separate answer lets the SHA and the tag of the comment disagree. The template uses the value of the render.
- **Get the SHA in a `_tasks` command or in `devops repos onboard`.**: The template has no `_tasks`, so Copier runs it without `--trust`. The copier manager of Renovate runs `copier update`, not `devops repos onboard`, so the SHA of the next release would not change.

## Risks

- A render from a folder that is not a git repository gives `None` for `vcs_ref_hash`, which would render `@None # ` (actionlint 1.7.12 accepts it). Copier 9.19.1 does not validate the default of a question with `when: false` under `--defaults` (`copier/_main.py:636-670`), so a validator cannot refuse it. Each caller instead renders `_copier_conf.vcs_ref_hash or vcs_ref_hash_missing | mandatory("...")`: the filter `mandatory` of `jinja2_ansible_filters`, which Copier loads by default, raises its message for the undefined name only when the hash is empty. The render then fails with "Copier gives no commit of the template" and writes no file (`tests/test-repository-template.sh`).
