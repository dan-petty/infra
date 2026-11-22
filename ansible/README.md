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

The role `example` and the play `example.yml` are fixtures: they let the Ansible job of CI prove
that `ansible-lint` and `ansible-galaxy collection build` run. dan-petty/infra#7 and
dan-petty/infra#8 add the real roles and plays.

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
