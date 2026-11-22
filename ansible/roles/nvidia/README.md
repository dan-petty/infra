# Role nvidia

The role `dan_petty.infra.nvidia` installs the NVIDIA driver and the NVIDIA Container Toolkit on a
Debian k3s node with an NVIDIA GPU. It:

- Adds the NVIDIA CUDA apt source and the NVIDIA Container Toolkit apt source (DEB822).
- Installs the kernel headers, the driver packages and the Container Toolkit packages.
- Reboots the host one time when the nouveau driver is loaded and `nvidia-smi` does not work.
- Writes the CDI specification `/etc/cdi/nvidia.yaml` and starts `nvidia-persistenced`.
- Sets a persistent GPU power limit when `nvidia_gpu_power_limit` is set.
- Restarts the k3s node service when it installs a new Container Toolkit package. k3s finds the
  NVIDIA runtime only when its node service starts, and then writes it to its own containerd
  config.

## Variables

`meta/argument_specs.yml` declares each variable. `ansible-doc -t role dan_petty.infra.nvidia`
shows them. A play, `group_vars` or `host_vars` can replace each default.

| Variable | Default | Content |
| --- | --- | --- |
| `devops_infra_node_service` | None. Required inventory variable. | The systemd unit that runs the Kubernetes node: `k3s` on a server, `k3s-agent` on an agent. Set it in the inventory for each host. devops-cli `devops infra onboard` checks it. |
| `nvidia_cuda_repo_url` | The Debian 13 amd64 CUDA repository | The CUDA apt repository of the current driver branch. |
| `nvidia_cuda_repo_gpg` | The key of that repository | The URL of the signing key of `nvidia_cuda_repo_url`. |
| `nvidia_legacy_cuda_repo_url` | The Debian 12 amd64 CUDA repository | The CUDA apt repository of a pinned driver branch ("Pin a driver branch"). |
| `nvidia_driver_branch` | Not set | The driver branch to pin, for example `"580"`. |
| `nvidia_driver_packages` | `nvidia-driver`, `nvidia-driver-cuda`, `nvidia-kernel-open-dkms` | The driver packages. |
| `nvidia_container_toolkit_repo_url` | The stable amd64 repository of NVIDIA | The apt repository of the NVIDIA Container Toolkit. |
| `nvidia_container_toolkit_repo_gpg` | The key of that repository | The URL of the signing key of the Container Toolkit repository. |
| `nvidia_container_toolkit_packages` | The four Container Toolkit packages | The Container Toolkit packages. |
| `nvidia_ctk_path` | `/usr/bin/nvidia-ctk` | The binary that writes the CDI specification. |
| `nvidia_gpu_power_limit` | Not set | The GPU power limit in watts ("Set a GPU power limit"). |

## Run the role

```yaml
- name: Install the NVIDIA driver and the Container Toolkit
  hosts: gpu_nodes
  become: true
  roles:
    - role: dan_petty.infra.nvidia
```

Run the play with `--check --diff` first. A play that updates the packages of a host can add the
apt sources of the role and no other task:

```yaml
- name: Add the NVIDIA apt sources
  ansible.builtin.import_role:
    name: dan_petty.infra.nvidia
    tasks_from: apt_sources
```

The role can run before k3s is on the host. The restart of the node service then fails, and the run
continues.

## Pin a driver branch

The R580 driver branch is the last branch that supports Maxwell, Pascal and Volta GPUs. The Debian
13 CUDA repository of NVIDIA has only the current branch. The R580 packages are only in the Debian
12 CUDA repository. A GPU older than Turing also needs the proprietary module `nvidia-kernel-dkms`:
the open kernel modules (`nvidia-kernel-open-dkms`) need Turing (`sm_75`) or newer.

A host selects the pinned branch in its `host_vars`:

```yaml
nvidia_driver_branch: "580"
nvidia_driver_packages:
  - nvidia-driver
  - nvidia-driver-cuda
  - nvidia-kernel-dkms
  - nvidia-persistenced
```

When `nvidia_driver_branch` is set, the role manages these files:

| File | Content |
| --- | --- |
| `/etc/apt/sources.list.d/cuda-debian12-x86_64.sources` | The Debian 12 CUDA repository (`Trusted: yes`), the only source of the R580 packages. |
| `/etc/apt/preferences.d/nvidia-driver-pin` | The pin of each driver package to `580*` at priority 1000, so apt never moves to a newer branch. |

A host without `nvidia_driver_branch` gets neither file: the role removes them. Change the
variables, not these files on a host. The cleanup list of `tasks/apt_sources.yml` removes older
copies of the source, such as the one-line `cuda-debian12.list`. Never add the managed
`cuda-debian12-x86_64.sources` to that list.

Check a host with a pinned branch:

```sh
ssh <user>@<host> 'nvidia-smi --query-gpu=name,driver_version,compute_cap --format=csv; apt-cache policy nvidia-driver'
```

Expect driver `580.x` and an `nvidia-driver` candidate from `.../repos/debian12/x86_64`.

### Why the Debian 12 repository is trusted

NVIDIA signs the Debian 12 repository with its legacy key `3BF863CC`. The binding signature of that
key uses SHA-1. Since 2026-02-01, the signature verifier of apt (`sqv`, Sequoia) refuses SHA-1
bindings, and NVIDIA did not sign the key again. `Trusted: yes` lets apt install from the repository,
so unattended `apt-get -y` upgrades continue to work. It also stops the signature check for that
repository: HTTPS to `developer.download.nvidia.com` is then its only integrity protection.

`apt-get update` still reports the failed check (`Signature verification failed ... Missing key
EB693B3035CD5710E231E123A4B469963BF863CC`) on each run. This is expected.

To use the signature check again, give the source
`Signed-By: /usr/share/keyrings/cuda-archive-keyring.gpg` (from the package `cuda-keyring`) in place
of `Trusted`. Then extend the SHA-1 cutoff of apt on each host with a pinned branch: copy
`/usr/share/apt/default-sequoia.config` to `/etc/crypto-policies/back-ends/apt-sequoia.config` and
set a later `sha1.second_preimage_resistance` date.

## Set a GPU power limit

Set `nvidia_gpu_power_limit` in the `host_vars` of each host to a value in the range of its card.
`nvidia-smi -q -d POWER` shows the range. The role writes the unit `nvidia-power-limit`, which sets
the limit at each boot. A card that refuses the limit makes the task "Enable and apply the GPU power
limit service" fail, so the GPU does not stay without a limit and with no message.

Check the host: `systemctl is-enabled nvidia-power-limit` prints `enabled`, and
`nvidia-smi --query-gpu=name,power.limit --format=csv,noheader` shows the limit.
