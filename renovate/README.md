# Renovate presets

This folder holds the shared Renovate presets of the repositories of dan-petty. A repository
extends a preset in its `renovate.json`. infra itself extends them with the `local>` form in
`.github/renovate.json`.

| Preset | Content | Extend it with |
| --- | --- | --- |
| `base.json` | The schedule, the groups, the labels, the reviewers, the commit messages, the vulnerability alerts and the automerge of each update after all checks pass. | `github>dan-petty/infra//renovate/base` |
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
out the tag. The body of the pull request holds the full name.

## Test

`tests/test-renovate-presets.sh` (CI job "Renovate presets") runs the config validator of
Renovate in strict mode on the two presets and on `.github/renovate.json`. The fixture
`tests/renovate/` is a consumer repository: it holds one pin of infra in each form of README.md,
"Pin a release", and a CloudNativePG Cluster. The local platform of Renovate does not resolve a
preset of a repository, so the test merges `base.json` and `k8s.json` into one config. Then
`renovate --platform=local --dry-run=extract` reads a copy of the fixture with that config. The
test checks that Renovate reads each pin of infra with the datasource `github-tags` or
`git-tags`, and the image of the Cluster. The built-in managers of Renovate read each form of a
pin of infra, so `k8s.json` has no custom manager for them.

The extract does not apply the package rules. Thus the test also runs
`renovate --platform=local --dry-run=lookup` on the copy of the fixture, and checks that the
lookup of each pin of infra gets the repository `https://github.com/dan-petty/infra` with no
warning. This proves the package rule of the Ansible collection: the ansible-galaxy manager gives a
collection from github.com the URL of the repository as its name, and the lookup of `github-tags`
reads only the form `owner/repository`. The lookup reads the GitHub API and needs a token that can
read public repositories:

```sh
RENOVATE_GITHUB_COM_TOKEN=<token> mise exec -- tests/test-renovate-presets.sh
```

Without the token, the test skips the lookup. In CI, the job gives its read-only token, and the
test fails without it.
