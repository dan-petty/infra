# infra

The shared infrastructure templates of the repositories of dan-petty, and the checks that test
them. A template that two or more consumers use, or a platform stack that any service can use, is
here. A template of one consumer stays with that consumer (devops-cli ADR 0032, "Infrastructure
templates live in four homes").

## infra holds no private data

infra is public. It holds no secret and no value of one environment: no real domain, no host or
node name, no private address, no device path, no inventory, no Secret and no token. Templates,
tests and documents use the placeholder `<domain>`, the domain `example.com` and the RFC 5737
addresses 192.0.2.0/24, 198.51.100.0/24 and 203.0.113.0/24. The consumer gives its own values.
The private-data guard of CI refuses each of these values ("Private-data guard").

## Layout

| Folder | Content |
| --- | --- |
| `k8s/bases/` | Kustomize bases. |
| `k8s/components/` | Kustomize components, with their Prometheus rules in `rules/`. |
| `k8s/tests/` | The test overlay of each base and component. |
| `charts/` | The Helm charts that infra writes, with their test values and unit tests. |
| `helm/` | The values templates of upstream Helm charts, each with a test chart that pins the upstream chart. |
| `ansible/` | The Ansible collection `dan_petty.infra`: `galaxy.yml`, `roles/`, `playbooks/` and its `tests/`. |
| `tf/modules/` | OpenTofu modules. |
| `tf/examples/` | An example for each OpenTofu module. |
| `renovate/` | Renovate presets that other repositories extend. |
| `templates/` | The files of the Copier template of a new repository (`templates/repository/`, with the questions in `copier.yml` in the root) and the schema of its settings baseline. |
| `docs/` | Documents that apply to more than one template. |
| `.github/workflows/` | CI (`ci.yml`), the reusable workflows `k8s-validate.yml`, `pr-title.yml` and `release.yml`, and the callers of infra: the title check (`pr-title-caller.yml`) and the releases (`release-caller.yml`). |

The README of each folder tells its content and the consumers of each template. Each folder that
a CI job checks has an `example` fixture, so CI proves that each check runs; the test chart of
each values template is the fixture of `helm/`. The fixture of `renovate/` is `tests/renovate/`.
The real templates so far are the Renovate presets in `renovate/` (dan-petty/infra#6), the chart
`charts/service-tenant` (dan-petty/infra#10, with its secret store from dan-petty/infra#12), the
Ansible roles `common`, `data_disk`, `nvidia`, `gvisor` and `cpu_tuning`, and the generic plays (dan-petty/infra#7, dan-petty/infra#8), the base `k8s/bases/valkey`
with its components `valkey-persistence`, `valkey-exporter` and `valkey-acl` (dan-petty/infra#13),
the base `k8s/bases/service-repos` (dan-petty/infra#11, [docs/service-repos.md](docs/service-repos.md)),
the base `k8s/bases/cloudflared` (dan-petty/infra#16; the upstream chart `cloudflare-tunnel-remote` lacks the required 2-replica default with anti-affinity, fixed Secret name `cloudflared-token`, and PodDisruptionBudget),
the values template `helm/external-secrets` of External Secrets Operator (dan-petty/infra#12), the
values templates `helm/cert-manager` and `helm/traefik` (dan-petty/infra#16), the
OpenTofu modules `aws-eks`, `azure-aks` and `gcp-gke` with their examples (dan-petty/infra#9), and
the Copier template of a new repository (dan-petty/infra#37, [templates/README.md](templates/README.md)).
The fixture of `templates/` is each answer set of `tests/test-repository-template.sh`.
More templates come with later items, such as #14 to
#19 (Kubernetes bases and components, and Helm values templates).

## Pin a release

A consumer pins infra at a release tag `vX.Y.Z`, never at `main`. Renovate updates each pin.

| Form | Pin |
| --- | --- |
| Kustomize base or component | `https://github.com/dan-petty/infra//k8s/bases/<base>?ref=vX.Y.Z` |
| Argo CD source | `repoURL: https://github.com/dan-petty/infra.git` with `targetRevision: vX.Y.Z` |
| Ansible collection | `name: https://github.com/dan-petty/infra.git#/ansible/`, `type: git`, `version: vX.Y.Z` |
| OpenTofu module | `git::https://github.com/dan-petty/infra.git//tf/modules/<module>?ref=vX.Y.Z` |
| Reusable workflow | `uses: dan-petty/infra/.github/workflows/<workflow>.yml@vX.Y.Z` |
| Copier template | `copier copy --vcs-ref vX.Y.Z https://github.com/dan-petty/infra.git <dir>`, which writes `_commit: vX.Y.Z` into `.copier-answers.yml` ([templates/README.md](templates/README.md)) |

## Releases

[release-please](https://github.com/googleapis/release-please-action) makes each release. On each
push to `main`, `.github/workflows/release-caller.yml` calls the reusable workflow `release.yml` of
the same commit ("Call the reusable workflows"), which opens or updates one release pull request.
It holds the next version in `version.txt`, `.release-please-manifest.json` and
`ansible/galaxy.yml`, the next tag `vX.Y.Z` in `k8s/bases/service-repos/applicationsets.yaml`, and
the new entry of `CHANGELOG.md`. The workflow turns on auto-merge and requests review (`dan-petty` by default) on the release pull request, and
GitHub merges it when its required checks pass; a person can also merge it. The next run of
release-please creates the tag `vX.Y.Z` and its GitHub release. `.github/CODEOWNERS` also names
`dan-petty` as the owner of each file, so GitHub asks dan-petty to review each pull request on
public repositories. With the repository setting *immutable releases*, nobody can move
or delete a published tag, so a pin always gets the same content.

release-please reads the type of each commit on `main` since the last release. The largest change
gives the next version. The merge settings of the repository decide if the pull request title or the
commit subjects of the branch land on `main`. Thus write the pull request title and each commit
subject as a Conventional Commit. `.github/workflows/pr-title-caller.yml` calls the reusable workflow
`pr-title.yml` of the same commit, which checks the title of each pull request and the subject of
the commit of a pull request with one commit:

| Commit | Next version |
| --- | --- |
| The first release | `v0.1.0` (`initial-version` of `release-please-config.json`) |
| A breaking change: `!` after the type, or a `BREAKING CHANGE:` footer | The next major version. Renovate opens a major update as a separate pull request. |
| `feat` | The next minor version |
| `fix`, `perf` or `revert` | The next patch version |
| `build`, `chore`, `ci`, `docs`, `refactor`, `style` or `test` | No release of its own |

A change of a template input that a consumer must follow is a breaking change.

`extra-files` of the package `.` in `release-please-config.json` lists the other files that get the
new version:

- `ansible/galaxy.yml` has the type `yaml` and the path `$.version`, so the release pull request
  writes the new version into the key `version` of the collection. This updater writes the whole
  file again with js-yaml: it removes each comment and can change the quotes of a string. Thus
  `ansible/galaxy.yml` has no comments, and each string has the quotes that js-yaml writes.
- To keep a file that names its own release tag current, put the comment `x-release-please-version`
  on that line and add `{"type": "generic", "path": "<file>"}` to `extra-files`. The release pull
  request then writes the new version on that line only. A YAML file also needs the type
  `generic`: for a path with no type, release-please also sets a key `version` of the file with the
  updater `yaml`, which removes the comments. `k8s/bases/service-repos/applicationsets.yaml` pins
  the chart `charts/service-tenant` this way, so each release tag of the base names the chart of the
  same tag. `tests/test-service-repos.sh` checks that the pin is `v` and the version of
  `version.txt`.

The release App gives the token of the job, so the checks of `ci.yml` run on the release pull
request. A pull request that `GITHUB_TOKEN` opens starts no workflow. The job runs in the
environment `release`, which holds the variable `RELEASE_APP_CLIENT_ID` and the secret
`RELEASE_APP_PRIVATE_KEY` of the App. When one of them is missing, the job stops with an error that
names it.

## Call the reusable workflows

A repository calls a reusable workflow of infra at a release tag ("Pin a release"). The job that
calls it gives the permissions that the called job needs: a called workflow can only reduce them.
Each workflow runs the actions and the tools of its own infra commit, so a caller gets the versions
of its tag. infra calls each workflow of its own commit, so its CI tests them: `ci.yml` calls
`k8s-validate.yml`, `pr-title-caller.yml` calls `pr-title.yml` and `release-caller.yml` calls
`release.yml`. The job YAML of `ci.yml` runs [zizmor](https://docs.zizmor.sh/) over the workflows:
each action has a pin to a commit SHA, no job gets more permissions than it needs and no call passes
`secrets: inherit`. `.github/zizmor.yml` holds its settings.

`pr-title.yml` and `release.yml` set the concurrency of their job, with a group that starts with
`infra-`. A caller needs no concurrency group. When it sets one, the group must not start with
`infra-`: the same group in a caller and a called workflow can cancel the caller
([GitHub docs](https://docs.github.com/en/actions/reference/workflows-and-actions/reusing-workflow-configurations#supported-keywords-for-jobs-that-call-a-reusable-workflow)).

### `k8s-validate.yml`

`.github/workflows/k8s-validate.yml` (`on: workflow_call`) checks Kubernetes manifests, Helm charts
and Prometheus rules. It runs `kustomize build` and `helm template` into `kubeconform -strict` (with
the CRD schemas of the [datreeio CRDs-catalog](https://github.com/datreeio/CRDs-catalog), and the
non-standalone schema of `CustomResourceDefinition` of
[yannh/kubernetes-json-schema](https://github.com/yannh/kubernetes-json-schema)), kube-linter and
`trivy config` (HIGH and CRITICAL findings), and `helm lint --strict`, `helm unittest` and
`promtool check rules`. The render writes each object to its own file
`<n>-kustomize-<root>/` or `<n>-helm-<release>/`, then `<namespace>/` when the object has one, then
`<kind>-<name>.yaml`. Thus each finding names one object, and an entry of a trivy ignore file can
name the file of one object. A chart folder `test-chart` is the test chart of a values template
([helm/README.md](helm/README.md)). The workflow installs the tools of the `mise.lock` of its own
infra commit, so a caller gets the tool versions of its tag.

```yaml
jobs:
  k8s:
    uses: dan-petty/infra/.github/workflows/k8s-validate.yml@vX.Y.Z
    permissions:
      contents: read
    with:
      kustomize-roots: |
        k8s/overlays/example
      helm-charts: |
        charts/example
      promtool-rules: |
        k8s/rules/example.rules.yaml
```

| Input | Content |
| --- | --- |
| `kustomize-roots` | The Kustomize folders to build, one on each line. |
| `helm-charts` | The Helm chart folders to lint, render and test, one on each line. Each `ci/*-values.yaml` file of a chart gives one render. |
| `kube-linter-config` | The kube-linter config file of the caller. Empty selects the shared `.kube-linter.yaml` of infra. |
| `promtool-rules` | The Prometheus rule files to check, one on each line. |
| `trivy-ignorefile` | The trivy ignore file of the caller, in the form of `tf/.trivyignore.yaml`, which `trivy config` gets with `--ignorefile`. Empty gives no ignore file. |

Each path is relative to the root of the caller repository. The shared `.kube-linter.yaml` holds
the default checks of kube-linter, five more checks and two custom checks. `pvc-prune-protection`:
a PersistentVolumeClaim must have the Argo CD sync options `Prune=false` and `Delete=false`.
`network-policy-egress-alone`: a NetworkPolicy with egress rules must not have the type `Ingress`.

### `pr-title.yml`

`.github/workflows/pr-title.yml` (`on: workflow_call`) checks the title of a pull request with
[action-semantic-pull-request](https://github.com/amannn/action-semantic-pull-request): a
Conventional Commit, with a summary of at most 60 characters ("Releases"). For a pull request with
one commit, it also checks the subject of the commit (`validateSingleCommit`), because the squash
commit then gets that subject. The scope is optional. The scopes are the name after `scope/` of
each `scope/*` label of the `.github/labels.yml` of the caller, and `main`, the scope of the release
pull request. The job reads the labels file of the commit of the run with
`scripts/pr-title-scopes.sh` of its infra commit, so a new scope label needs no change of the
workflow. When the labels file is missing, the job stops with an error that names it.

```yaml
on:
  pull_request:
    types: [opened, edited, synchronize, reopened]
    branches:
      - main

permissions: {}

jobs:
  pr-title:
    name: PR title
    uses: dan-petty/infra/.github/workflows/pr-title.yml@vX.Y.Z
    permissions:
      contents: read
      pull-requests: read
```

The type `edited` runs the check again after a change of the title. The workflow has no inputs.
The check of the caller above has the name `PR title / Semantic PR title`.

### `release.yml`

`.github/workflows/release.yml` (`on: workflow_call`) runs release-please with the token of the
release App ("Releases"). Its job runs in the environment `release` of the caller, which holds the
variable `RELEASE_APP_CLIENT_ID` and the secret `RELEASE_APP_PRIVATE_KEY` of the App. A job that
calls a reusable workflow cannot set `environment`, so the called job sets it. The caller must
still pass the secret by name, and the job then gets the value of the environment secret
([GitHub docs](https://docs.github.com/en/actions/how-tos/reuse-automations/reuse-workflows#using-inputs-and-secrets-in-a-reusable-workflow)).
When the caller does not pass the secret, the run stops before the job starts. When the
environment does not hold the variable or the secret, the first step stops the job with an error
that names each missing credential. Keep the key only in the environment `release`: the workflows
of each branch can read a repository secret.

```yaml
on:
  push:
    branches:
      - main

permissions: {}

jobs:
  release:
    name: Release
    uses: dan-petty/infra/.github/workflows/release.yml@vX.Y.Z
    permissions: {}
    secrets:
      RELEASE_APP_PRIVATE_KEY: ${{ secrets.RELEASE_APP_PRIVATE_KEY }}
```

| Input | Content |
| --- | --- |
| `config-file` | The release-please config file of the caller, which holds the release type of each package. The default is `release-please-config.json`. |
| `manifest-file` | The release-please manifest file of the caller. The default is `.release-please-manifest.json`. |

| Output | Content |
| --- | --- |
| `release_created` | `true` when the run created the release of the root package, else empty. |
| `tag_name` | The tag of that release, such as `v1.2.3`, else empty. |

A later job of the caller can publish the release with `needs: release` and
`if: needs.release.outputs.release_created == 'true'`.

## Tools

The repository pins each tool of the checks. `mise.toml` and `mise.lock` pin the binary tools
(actionlint, gitleaks, helm, helm-unittest, jq, kube-linter, kubeconform, kustomize, Node, OpenTofu,
promtool, shellcheck, tflint, trivy, uv and yq), with the checksum of each download. The test of the
Renovate presets runs the Renovate release of `tests/test-renovate-presets.sh` with the `npx` of
that Node. `pyproject.toml` and `uv.lock` pin the Python tools (ansible-core, ansible-lint,
check-jsonschema, Copier, pre-commit, yamllint and zizmor). Install them into one shared cache
folder and into `.venv`:

```sh
export MISE_DATA_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/infra-tools/mise"
mise install --locked
uv sync --frozen
```

To change a version, edit `mise.toml` and run `mise lock --platform linux-x64,linux-arm64`, or edit
`pyproject.toml` and run `uv lock`. Renovate proposes each update.

## Checks

`.github/workflows/ci.yml` runs on each pull request, each push to `main` and each manual run
(`workflow_dispatch`). A job runs only when a change touches the files of its tool. A manual run
runs every job. The check `K8s` always reports, with the result of the validation job `K8s run`,
so a ruleset can require it. To run a job locally, run its command from the repository root:

| Job | Command |
| --- | --- |
| Private-data guard | `mise exec -- tests/test-private-data-scan.sh` and `mise exec -- scripts/private-data-scan.sh dir .` |
| K8s | `KUSTOMIZE_ROOTS="$(ls -d k8s/tests/*/)" HELM_CHARTS=$'charts/example\ncharts/service-tenant\nhelm/external-secrets/test-chart' PROMTOOL_RULES=k8s/components/example/rules/example.rules.yaml TRIVY_IGNORE_FILE=helm/.trivyignore.yaml mise exec -- scripts/k8s-validate.sh all` |
| K8s templates | `mise exec -- tests/test-service-repos.sh` and `mise exec -- tests/test-k8s-validate.sh` |
| kube-linter config | `mise exec -- tests/test-kube-linter-config.sh` |
| OpenTofu | `mise exec -- tofu fmt -check -recursive tf/`, `mise exec -- tflint --recursive --config "$PWD/.tflint.hcl"`, in each folder of `tf/examples/`: `mise exec -- trivy config --exit-code 1 --severity HIGH,CRITICAL --ignorefile tf/.trivyignore.yaml --skip-dirs '**/.terraform' --tf-vars <folder>/<name>.tfvars.example <folder>` (with no `--tf-vars` for a folder that has no such file; a bare `trivy config tf/` gets no variable values and reports GCP-0061), then `tofu init -backend=false` and `tofu validate`, and `mise exec -- tests/test-trivyignore.sh` |
| Ansible | `../.venv/bin/ansible-lint` and `../.venv/bin/ansible-galaxy collection build` in `ansible/`, and `tests/test-ansible-collection.sh` |
| YAML | `.venv/bin/yamllint --strict .` and `.venv/bin/zizmor --offline .github/workflows/` |
| actionlint | `mise exec -- actionlint`, `mise exec -- tests/test-pr-title-scopes.sh` and `mise exec -- tests/test-ci-check-names.sh` |
| shellcheck | `git ls-files -z '*.sh' \| xargs -0 mise exec -- shellcheck` |
| Renovate presets | `mise exec -- tests/test-renovate-presets.sh`, with a GitHub token in `RENOVATE_GITHUB_COM_TOKEN` for the lookup ([renovate/README.md](renovate/README.md#test)) |
| Repository template | `mise exec -- tests/test-repository-template.sh` ([templates/README.md](templates/README.md#test)) |

## Private-data guard

`scripts/private-data-scan.sh` runs gitleaks with `.gitleaks.toml`: the default rules of gitleaks
for secrets, and rules for RFC 1918, CGNAT and link-local addresses, for names that end in `.lan`
or `.local`, and for device paths. The allowlist admits the k3s default cluster CIDR
`10.42.0.0/16` and Service CIDR `10.43.0.0/16`, the block of each private range (such as
`10.0.0.0/8`), the Kubernetes cluster domain and the pseudo-devices such as `/dev/null`.
`tests/test-private-data-scan.sh` holds a case for each rule.

The guard also refuses each domain of the environment variable `PRIVATE_DOMAINS` (one domain on
each line) and each subdomain of it. In CI, the value comes from the Actions secret
`PRIVATE_DOMAINS`, so no file holds a real domain. When the secret is not set, the job writes a
warning in its log and its summary, and runs the other rules.

## Pre-commit hooks

After `uv sync --frozen`, run `.venv/bin/pre-commit install` once in each clone. The hooks of
`.pre-commit-config.yaml` refuse a commit on `main` and run the private-data guard on the staged
changes.

## License

[MIT](LICENSE).
