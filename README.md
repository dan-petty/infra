# infra

The shared infrastructure templates of the repositories of dan-petty, and the checks that test
them. A template that two or more consumers use, or a platform stack that any service can use, is
here. A template of one consumer stays with that consumer (devops-cli ADR 0032, "Infrastructure
templates live in four homes"). The reusable GitHub Actions workflows and the Copier template of a
new repository are in [dan-petty/github-workflows](https://github.com/dan-petty/github-workflows),
which releases only when they change.

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
| `.github/workflows/` | CI (`ci.yml`) and the callers of the reusable workflows of dan-petty/github-workflows: the title check (`pr-title-caller.yml`) and the releases (`release-caller.yml`). |

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
OpenTofu modules `aws-eks`, `azure-aks` and `gcp-gke` with their examples (dan-petty/infra#9).
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
| Reusable workflow | `uses: dan-petty/github-workflows/.github/workflows/<workflow>.yml@<sha> # vX.Y.Z`, a release of dan-petty/github-workflows ([its README](https://github.com/dan-petty/github-workflows#pin-a-release)) |
| Copier template | `copier copy --vcs-ref vX.Y.Z https://github.com/dan-petty/github-workflows.git <dir>`, a release of dan-petty/github-workflows ([its README](https://github.com/dan-petty/github-workflows#pin-a-release)) |

A caller of a reusable workflow pins `<sha>`, the commit of the tag (`git rev-parse vX.Y.Z^{commit}`),
with the tag in a comment: the github-actions manager of Renovate writes this form for a digest pin
(`pinDigests` of [renovate/base.json](renovate/base.json)), and a repository with a supply-chain
rule refuses a bare tag. Each pin has one owner. The template of dan-petty/github-workflows renders
the callers `.github/workflows/pr-title.yml` and `.github/workflows/release.yml` of a repository,
and the copier update of the template moves their pins. Renovate moves each other pin. infra holds
no render of the template: its callers in `ci.yml`, `pr-title-caller.yml` and `release-caller.yml`
are its own files, and Renovate moves their pins. A release of infra holds no workflow and no
template, so Renovate leaves a caller of a workflow of infra and a copier render of infra alone
([renovate/README.md](renovate/README.md#move-to-dan-pettygithub-workflows)).

## Releases

[release-please](https://github.com/googleapis/release-please-action) makes each release. On each
push to `main`, `.github/workflows/release-caller.yml` calls the reusable workflow `release.yml` of
dan-petty/github-workflows ("Call the reusable workflows"), which opens or updates one release pull
request. It holds the next version in `version.txt`, `.release-please-manifest.json` and
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
`pr-title.yml` of dan-petty/github-workflows, which checks the title of each pull request and the
subject of the commit of a pull request with one commit. It accepts the scopes of every repository
and the name after `scope/` of each `scope/*` label of `.github/labels.yml`. The next version
comes from the types:

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

infra calls the reusable workflows of
[dan-petty/github-workflows](https://github.com/dan-petty/github-workflows#call-the-reusable-workflows)
at the commit of a release tag, as each other repository calls them ("Pin a release"). Its README
gives the inputs, the outputs and the permissions of each workflow.

| Caller | Workflow | Check |
| --- | --- | --- |
| The job `k8s-validate` of `ci.yml` | `k8s-validate.yml`: the Kustomize roots, Helm charts and Prometheus rules of infra, with the judgments of `helm/.trivyignore.yaml` and `helm/.kubelinterignore.yaml` ([helm/README.md](helm/README.md)) | `K8s run / Validate`, reported by the check `K8s` ("Checks") |
| `pr-title-caller.yml` | `pr-title.yml` | `PR title / Semantic PR title` |
| `release-caller.yml` | `release.yml`, in the environment `release` | `Release / Release Please` |

The job YAML of `ci.yml` runs [zizmor](https://docs.zizmor.sh/) over the workflows: each action
and each reusable workflow has a pin to a commit SHA, no job gets more permissions than it needs
and no call passes `secrets: inherit`.

## Tools

The repository pins each tool of the checks. `mise.toml` and `mise.lock` pin the binary tools
(actionlint, gitleaks, helm, helm-unittest, jq, kube-linter, kubeconform, kustomize, Node, OpenTofu,
promtool, shellcheck, tflint, trivy, uv and yq), with the checksum of each download. The test of the
Renovate presets runs the Renovate release of `tests/test-renovate-presets.sh` with the `npx` of
that Node. `pyproject.toml` and `uv.lock` pin the Python tools (ansible-core, ansible-lint,
pre-commit, yamllint and zizmor). Install them into one shared cache
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
so a ruleset can require it. To run a job locally, run its command from the repository root. The K8s
job runs the script `scripts/k8s-validate.sh` of dan-petty/github-workflows at the tag of the pin
of `ci.yml`, so a local run takes it from a clone of that tag next to infra:
`git clone --depth 1 --branch vX.Y.Z https://github.com/dan-petty/github-workflows.git ../github-workflows`.

| Job | Command |
| --- | --- |
| Private-data guard | `mise exec -- tests/test-private-data-scan.sh` and `mise exec -- scripts/private-data-scan.sh dir .` |
| K8s | `KUSTOMIZE_ROOTS="$(ls -d k8s/tests/*/)" HELM_CHARTS=$'charts/example\ncharts/service-tenant\nhelm/external-secrets/test-chart' PROMTOOL_RULES=k8s/components/example/rules/example.rules.yaml TRIVY_IGNORE_FILE=helm/.trivyignore.yaml KUBE_LINTER_IGNORE_FILE=helm/.kubelinterignore.yaml mise exec -- ../github-workflows/scripts/k8s-validate.sh all` |
| K8s templates | `mise exec -- tests/test-service-repos.sh` |
| OpenTofu | `mise exec -- tofu fmt -check -recursive tf/`, `mise exec -- tflint --recursive --config "$PWD/.tflint.hcl"`, in each folder of `tf/examples/`: `mise exec -- trivy config --exit-code 1 --severity HIGH,CRITICAL --ignorefile tf/.trivyignore.yaml --skip-dirs '**/.terraform' --tf-vars <folder>/<name>.tfvars.example <folder>` (with no `--tf-vars` for a folder that has no such file; a bare `trivy config tf/` gets no variable values and reports GCP-0061), then `tofu init -backend=false` and `tofu validate`, and `mise exec -- tests/test-trivyignore.sh` |
| Ansible | `../.venv/bin/ansible-lint` and `../.venv/bin/ansible-galaxy collection build` in `ansible/`, and `tests/test-ansible-collection.sh` |
| YAML | `.venv/bin/yamllint --strict .` and `.venv/bin/zizmor --offline .github/workflows/` |
| actionlint | `mise exec -- actionlint` and `mise exec -- tests/test-ci-check-names.sh` |
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
