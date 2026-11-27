# Renovate presets

This folder holds the shared Renovate presets of the repositories of dan-petty. A repository
extends a preset in its `renovate.json`. infra itself extends them with the `local>` form in
`.github/renovate.json`.

| Preset | Content | Extend it with |
| --- | --- | --- |
| `base.json` | The schedule, the groups, the labels, the reviewers, the commit messages, the vulnerability alerts and the automerge of each update after all checks pass. The copier update of the repository template of dan-petty/github-workflows has one branch, with the newest release, and owns the pins of the callers that the template renders ("Copier update"). Renovate leaves each caller of a workflow of infra and each copier render of infra alone ("Move to dan-petty/github-workflows"). | `github>dan-petty/infra//renovate/base` |
| `k8s.json` | The managers of the Kubernetes manifests under `k8s/`: the kubernetes manager on each manifest, the argocd manager on each Application under `k8s/argocd/`, the helm-values manager on each values file and a custom manager for the `spec.imageName` image of a CloudNativePG Cluster. An Argo CD git source that tracks `main` gets no update. A package rule gives the Ansible collection of infra the lookup name `dan-petty/infra`. All pins of infra move in one pull request. | `github>dan-petty/infra//renovate/k8s` |

```json
{
  "$schema": "https://docs.renovatebot.com/renovate-schema.json",
  "extends": [
    "github>dan-petty/infra//renovate/base",
    "github>dan-petty/infra//renovate/k8s"
  ]
}
```

`base.json` started from the rules of the devops-cli preset `.github/renovate/base.json` at
devops-cli commit `4ff4b7c5d`.

The title check allows a summary of at most 60 characters (README.md, "Releases"), so `base.json`
shortens a long name in the title. An action and a devcontainer feature lose the leading part of
their reference. A container image with a registry host is named by the last two parts of its
reference: `ghcr.io/example/app/service` is `app/service`. A digest update of such an image leaves
out the tag. The body of the pull request holds the full name. Each form of the name of infra gets
the topic `dan-petty/infra`, each form of the name of dan-petty/github-workflows gets the topic
`dan-petty/github-workflows`, and its copier update gets `dan-petty/github-workflows template`.

## Copier update

The copier manager reads `.copier-answers.yml` of a repository that the template of
[dan-petty/github-workflows](https://github.com/dan-petty/github-workflows) rendered, and its pull
request runs `copier update`. Two rules of `base.json` give each file of the template one owner
(#225):

- The github-actions manager leaves the pin of dan-petty/github-workflows in
  `.github/workflows/pr-title.yml` and `.github/workflows/release.yml`, the callers that the
  template renders (`enabled: false` with `matchFileNames`). The copier update moves them with the
  other files of the template. A caller in another file, such as one of `k8s-validate.yml`, gets its
  updates.
- The copier manager has one branch: `separateMajorMinor: false` puts each new release into one
  bucket, so Renovate proposes only the newest release, and `separateMinorPatch: false` keeps the
  minor number out of the branch name of a patch update. With the split, a repository at `v0.24.1`
  of the template, then in infra, got a patch branch to `v0.24.3` and a minor branch to `v0.25.2`
  that changed the same files (Renovate 45.1.0 `--dry-run=lookup`).

## Move to dan-petty/github-workflows

The reusable workflows and the repository template moved from infra to dan-petty/github-workflows
(#217). A release of infra after the move holds neither: a caller at that tag calls a workflow that
does not exist, and `copier update` to that tag writes the files of the root of infra into the
repository and deletes the files of the template, with exit code 0 (Copier 9.19.1). So a rule of `base.json` turns off the github-actions manager and the
copier manager for each form of the name of infra, in each file. A repository moves once:

1. Write `_src_path: https://github.com/dan-petty/github-workflows.git` into
   `.copier-answers.yml`, then run `copier recopy --skip-answered --defaults --overwrite --vcs-ref
   vX.Y.Z` with a release tag of dan-petty/github-workflows. Copier renders the callers
   `pr-title.yml` and `release.yml` at the commit of that tag, and keeps the answers.
2. Each other caller, such as one of `k8s-validate.yml`, changes `dan-petty/infra` to
   `dan-petty/github-workflows` in its `uses:` line, at the commit of the same tag. Renovate then
   moves the pin.

## Test

`tests/test-renovate-presets.sh` (CI job "Renovate presets") runs the config validator of
Renovate in strict mode on the two presets and on `.github/renovate.json`. The fixture
`tests/renovate/` is a consumer repository: it holds one pin of infra in each form of README.md,
"Pin a release", a render of the repository template of dan-petty/github-workflows with the caller
that it renders, a caller of `k8s-validate.yml`, a caller and a copier render of infra from before
the move, and a CloudNativePG Cluster. The local platform of Renovate does not resolve a preset of a repository, so the test
merges `base.json` and `k8s.json` into one config. Then
`renovate --platform=local --dry-run=extract` reads a copy of the fixture with that config. The
test checks that Renovate reads each pin of infra and of dan-petty/github-workflows with the
datasource `github-tags` or `git-tags`, and the image of the Cluster. The built-in managers of
Renovate read each form of a pin, so `k8s.json` has no custom manager for them.

The extract does not apply the package rules. Thus the test also runs
`renovate --platform=local --dry-run=lookup` on the copy of the fixture, and checks that the
lookup of each pin gets the repository of the pin with no warning, that Renovate leaves the caller
that the template renders to the copier update and each caller and copier render of infra alone
(the skip reason `disabled`), and that the copier update gets at most one update. This proves the package rule of the Ansible collection: the ansible-galaxy manager gives a
collection from github.com the URL of the repository as its name, and the lookup of `github-tags`
reads only the form `owner/repository`. The lookup reads the GitHub API and needs a token that can
read public repositories:

```sh
RENOVATE_GITHUB_COM_TOKEN=<token> mise exec -- tests/test-renovate-presets.sh
```

Without the token, the test skips the lookup. In CI, the job gives its read-only token, and the
test fails without it.
