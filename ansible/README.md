# Ansible collection dan_petty.infra

This folder is the Ansible collection `dan_petty.infra`: the shared roles and playbooks of the
infrastructure. It holds no inventory, no host name and no value of one environment. The consumer
gives the hosts and the values.

| Path | Content |
| --- | --- |
| `galaxy.yml` | The name, the version and the license of the collection. It has no comments. |
| `meta/runtime.yml` | The ansible-core versions that the collection supports. |
| `roles/<role>/` | One role, with `meta/argument_specs.yml` for its variables. |
| `playbooks/<play>.yml` | One play. It takes its hosts from the variable `target_hosts` and has no default host. |
| `tests/` | The example inventory and the test plays of the collection. The build leaves them out. |

## Roles and plays

| Role | Play | Content |
| --- | --- | --- |
| [`common`](roles/common/README.md) | None | Baseline configuration for Debian k3s nodes: APT sources, headless GRUB, base packages, automation user, kernel modules, sysctl, and UFW firewall. |
| [`data_disk`](roles/data_disk/README.md) | `08_mount_nvme.yml` | Format and mount dedicated data block devices (such as NVMe storage). |
| [`nvidia`](roles/nvidia/README.md) | None | The NVIDIA driver and the NVIDIA Container Toolkit of a Debian k3s node, a driver branch pin and a GPU power limit. |
| [`gvisor`](roles/gvisor/README.md) | `gvisor.yml` | The pinned gVisor runtime (`runsc`) of a Debian k3s node, and the node label of its RuntimeClass. |
| [`cpu_tuning`](roles/cpu_tuning/README.md) | `cpu_tuning.yml` | The CPU power limits and the disabled CPU idle states of a host, at each boot. |
| None | `00_bootstrap_user.yml` | Bootstrap dedicated Ansible automation user on Debian nodes. |
| None | `06_cluster_backup.yml` | Snapshot k3s control plane database (SQLite/etcd), archive TLS tokens, certificates and manifests. |
| None | `09_system_update.yml` | Rolling system package upgrade and maintenance across Debian nodes. |
| None | `11_secrets_encryption.yml` | Encrypt Kubernetes Secrets at rest on the k3s server (aescbc). |
| None | `13_crash_capture.yml` | Capture kernel log of a host crash: kdump, hardware watchdog, persistent journal, and optional netconsole. |
| None | `health_check.yml` | Diagnostic inspection across Debian nodes: uptime, memory, disk, k3s service, and NVIDIA GPU telemetry. |
| `example` | `example.yml` | Fixtures: they let the Ansible job of CI prove that `ansible-lint` and `ansible-galaxy collection build` run. |

The consumers of `nvidia`, `gvisor` and `cpu_tuning` are the Debian k3s clusters with NVIDIA GPU
nodes, gVisor nodes or CPU settings of a BIOS to set from Linux. The README of each role tells its
variables and its runbook. A role variable that only the inventory can give, such as
`devops_infra_node_service`, has no default: the argument check of the role stops a host that does
not set it. A consumer that runs a play from its own repository keeps a thin play that lists the
role, with the hosts and the settings of its inventory.

## Version

The collection has the version of the release of infra. The release pull request of release-please
writes the new version into the key `version` of `galaxy.yml` (README.md of the repository,
"Releases"). That updater writes the whole file again with js-yaml, so it removes each comment.
Thus `galaxy.yml` has no comments: write each note about the collection in this README.

## Use the collection

Install the collection from git at a release tag of infra, in the `requirements.yml` of the consumer:

```yaml
collections:
  - name: https://github.com/dan-petty/infra.git#/ansible/
    type: git
    version: vX.Y.Z
```

Then call a role or a play by its full name, for example
`ansible-playbook dan_petty.infra.example -e target_hosts=<group>`.

## Check the collection

From the folder `ansible/`, after `uv sync --frozen` in the repository root:

```sh
../.venv/bin/ansible-lint
../.venv/bin/ansible-galaxy collection build --output-path ..
```

The build writes `dan_petty-infra-<version>.tar.gz`, with the version of `galaxy.yml`.

From the repository root, `tests/test-ansible-collection.sh` builds the collection and installs the
archive into a temporary folder. Then it checks the syntax of each play, reads the argument specs of
each role with `ansible-doc`, and runs the test plays of `tests/` with the example inventory
`tests/inventory/example`. A test play runs no task on a host: the hosts of the example inventory
have RFC 5737 addresses. Add a test play to `tests/` for each new behavior of a role.
