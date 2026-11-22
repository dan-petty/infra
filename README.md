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
| `docs/` | Documents that apply to more than one template. |
| `.github/workflows/` | CI (`ci.yml`), the releases (`release.yml`) and the reusable workflow `k8s-validate.yml`. |

The README of each folder tells its content and the consumers of each template. Each folder that
a CI job checks has an `example` fixture, so CI proves that each check runs; `helm/` gets its
first content with a later item. The fixture of `renovate/` is `tests/renovate/`. The real
templates so far are the Renovate presets in `renovate/` (dan-petty/infra#6), the chart
`charts/service-tenant` (dan-petty/infra#10), the Ansible roles `nvidia`, `gvisor` and
`cpu_tuning` (dan-petty/infra#7), the base `k8s/bases/valkey` with its components
`valkey-persistence`, `valkey-exporter` and `valkey-acl` (dan-petty/infra#13), the base
`k8s/bases/service-repos` (dan-petty/infra#11, [docs/service-repos.md](docs/service-repos.md)), and
the OpenTofu modules `aws-eks`, `azure-aks` and `gcp-gke` with their examples (dan-petty/infra#9).
More templates come with later items, such as #8 (the Ansible role common and plays) and #12 and
#14 to #19 (Kubernetes bases and components, and Helm values templates).

## Pin a release

A consumer pins infra at a release tag `vX.Y.Z`, never at `main`. Renovate updates each pin.

| Form | Pin |
| --- | --- |
| Kustomize base or component | `https://github.com/dan-petty/infra//k8s/bases/<base>?ref=vX.Y.Z` |
| Argo CD source | `repoURL: https://github.com/dan-petty/infra.git` with `targetRevision: vX.Y.Z` |
| Ansible collection | `name: https://github.com/dan-petty/infra.git#/ansible/`, `type: git`, `version: vX.Y.Z` |
| OpenTofu module | `git::https://github.com/dan-petty/infra.git//tf/modules/<module>?ref=vX.Y.Z` |
| Reusable workflow | `uses: dan-petty/infra/.github/workflows/k8s-validate.yml@vX.Y.Z` |

## Releases

[release-please](https://github.com/googleapis/release-please-action) makes each release. On each
push to `main`, `.github/workflows/release.yml` opens or updates one release pull request. It holds
the next version in `version.txt`, `.release-please-manifest.json` and `ansible/galaxy.yml`, the
next tag `vX.Y.Z` in `k8s/bases/service-repos/applicationsets.yaml`, and the new entry of
`CHANGELOG.md`. When a person merges the release pull request, release-please creates the tag
`vX.Y.Z` and its GitHub release. With the repository setting *immutable releases*, nobody can move
or delete a published tag, so a pin always gets the same content.

release-please reads the type of each commit on `main` since the last release. The largest change
gives the next version. The merge settings of the repository decide if the pull request title or the
commit subjects of the branch land on `main`. Thus write the pull request title and each commit
subject as a Conventional Commit:

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

## Call the reusable workflow

`.github/workflows/k8s-validate.yml` (`on: workflow_call`) checks Kubernetes manifests, Helm charts
and Prometheus rules. It runs `kustomize build` and `helm template` into `kubeconform -strict` (with
the CRD schemas of the [datreeio CRDs-catalog](https://github.com/datreeio/CRDs-catalog)),
kube-linter and `trivy config` (HIGH and CRITICAL findings), and `helm lint --strict`,
`helm unittest` and `promtool check rules`. It installs the tools of the `mise.lock` of its own
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

Each path is relative to the root of the caller repository. The shared `.kube-linter.yaml` holds
the default checks of kube-linter, five more checks and the custom check `pvc-prune-protection`: a
PersistentVolumeClaim must have the Argo CD sync options `Prune=false` and `Delete=false`.

## Tools

The repository pins each tool of the checks. `mise.toml` and `mise.lock` pin the binary tools
(actionlint, gitleaks, helm, helm-unittest, jq, kube-linter, kubeconform, kustomize, Node, OpenTofu,
promtool, shellcheck, tflint, trivy, uv and yq), with the checksum of each download. The test of the
Renovate presets runs the Renovate release of `tests/test-renovate-presets.sh` with the `npx` of
that Node. `pyproject.toml` and
`uv.lock` pin the Python tools (ansible-core, ansible-lint, pre-commit and yamllint). Install them
into one shared cache folder and into `.venv`:

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
runs every job. To run a job locally, run its command from the repository root:

| Job | Command |
| --- | --- |
| Private-data guard | `mise exec -- tests/test-private-data-scan.sh` and `mise exec -- scripts/private-data-scan.sh dir .` |
| K8s | `KUSTOMIZE_ROOTS="$(ls -d k8s/tests/*/)" HELM_CHARTS=$'charts/example\ncharts/service-tenant' PROMTOOL_RULES=k8s/components/example/rules/example.rules.yaml mise exec -- scripts/k8s-validate.sh all` |
| K8s templates | `mise exec -- tests/test-service-repos.sh` |
| kube-linter config | `mise exec -- tests/test-kube-linter-config.sh` |
| OpenTofu | `mise exec -- tofu fmt -check -recursive tf/`, `mise exec -- tflint --recursive --config "$PWD/.tflint.hcl"`, and in each folder of `tf/examples/`: `mise exec -- trivy config --exit-code 1 --severity HIGH,CRITICAL --ignorefile tf/.trivyignore.yaml --skip-dirs '**/.terraform' --tf-vars <folder>/<name>.tfvars.example <folder>` (with no `--tf-vars` for a folder that has no such file; a bare `trivy config tf/` gets no variable values and reports GCP-0061), then `tofu init -backend=false` and `tofu validate` |
| Ansible | `../.venv/bin/ansible-lint` and `../.venv/bin/ansible-galaxy collection build` in `ansible/`, and `tests/test-ansible-collection.sh` |
| YAML | `.venv/bin/yamllint --strict .` |
| actionlint | `mise exec -- actionlint` |
| shellcheck | `git ls-files -z '*.sh' \| xargs -0 mise exec -- shellcheck` |
| Renovate presets | `mise exec -- tests/test-renovate-presets.sh`, with a GitHub token in `RENOVATE_GITHUB_COM_TOKEN` for the lookup ([renovate/README.md](renovate/README.md#test)) |

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
