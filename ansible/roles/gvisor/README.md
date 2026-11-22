# Role gvisor

The role `dan_petty.infra.gvisor` installs the pinned gVisor runtime (`runsc`) on a Debian k3s node
and labels the node. gVisor is a kernel in user space. A pod of a RuntimeClass with the handler
`runsc` runs on it. The pod gets to the host kernel only through a small, filtered set of system
calls of the gVisor Sentry, so most defects of the host kernel are out of its reach. k3s finds runc,
crun, the NVIDIA runtimes and the Wasm runtimes, but not `runsc`. The play
`dan_petty.infra.gvisor` (`playbooks/gvisor.yml`) runs the role on one host at a time.

The role does these steps on each host:

1. It checks that the host is an amd64 k3s agent with cgroup v2. A restart of the node service of a
   k3s server stops its API server and its datastore. So the role runs on a server only when a
   reviewed change sets `gvisor_allow_server: true`.
2. It adds the gVisor apt source in the date suite of the pin (`gvisor_release`), with the key in
   `files/gvisor-archive-key.asc`. It checks the key file against its SHA-256 in
   `files/gvisor-archive-key.asc.sha256` and never downloads a key. `vars/main.yml` tells how to
   check a new key.
3. It holds `runsc` at `gvisor_version` with an apt preference, so a dist-upgrade does not move it,
   and installs it.
4. It writes `/etc/rancher/k3s/runsc.toml` (`systemd-cgroup = "true"`: the kubelet uses the systemd
   cgroup driver).
5. It writes `/var/lib/rancher/k3s/agent/etc/containerd/config-v3.toml.tmpl`. The template starts
   with the k3s base template and adds the runtime `runsc`. The role owns the whole file. It stops
   and changes nothing when a template exists that it did not write, or when a legacy
   `config.toml.tmpl` exists: k3s reads the legacy file only when `config-v3.toml.tmpl` is missing,
   so the new file would remove its settings with no message.
6. It restarts the node service when the template changes, and also when containerd does not list
   `runsc` yet (a run that stopped before the restart took effect). Then it waits until the node is
   Ready. The running containers stay up (`KillMode=process`).
7. It checks that `k3s crictl info` lists the runtime `runsc` with its `ConfigPath`, and that the
   kubelet lists the handler `runsc` (`.status.runtimeHandlers` of the node). When a step from the
   template write to these checks fails, the role puts back the template of before, restarts the
   node service again, waits for containerd and stops with the first error. The node then has no
   new label.
8. It sets the node label `gvisor_node_label=true` as the last step, so no pod of the RuntimeClass
   comes to a node where containerd does not have `runsc`.

The role does not reboot. It is safe to run two times: the second run changes nothing.

## Variables

`meta/argument_specs.yml` declares each variable. `ansible-doc -t role dan_petty.infra.gvisor`
shows them. A play, `group_vars` or `host_vars` can replace each default. The fixed paths and the
key values that the files of the role name are in `vars/main.yml`.

| Variable | Default | Content |
| --- | --- | --- |
| `devops_infra_node_service` | None. Required inventory variable. | The systemd unit that runs the Kubernetes node: `k3s` on a server, `k3s-agent` on an agent. |
| `gvisor_node_role` | None. Required. | The k3s role of the host: `agent` or `server`. |
| `gvisor_allow_server` | `false` | Let the role run on a k3s server. |
| `gvisor_version` | The pinned release, `<date>.<point>` | The exact `runsc` version. |
| `gvisor_release` | The date part of `gvisor_version` | The date suite of the apt source. |
| `gvisor_repo_url` | `https://storage.googleapis.com/gvisor/releases` | The apt repository of gVisor. |
| `gvisor_node_label` | `node-restriction.kubernetes.io/gvisor` | The node label that the RuntimeClass selects. |
| `gvisor_node_name` | `inventory_hostname` | The Kubernetes node name. Set it when the node name is not the inventory name. |
| `gvisor_server_group` | `k3s_server` | The inventory group of the k3s servers. |
| `gvisor_api_host` | The first host of `gvisor_server_group`, else the host itself | The host that runs kubectl for the node checks and the label. |
| `gvisor_k3s_bin` | `/usr/local/bin/k3s` | The k3s binary, which holds kubectl and crictl. |

The NodeRestriction admission plugin of k3s stops a kubelet from setting a label under
`node-restriction.kubernetes.io/`. So a node cannot label itself to attract the pods of the
RuntimeClass.

## Run it

1. Plan the run: `ansible-playbook dan_petty.infra.gvisor -i <inventory> -e target_hosts=<group>
   --limit <host> --check --diff`. On the first run, the plan shows the source, the pin,
   `runsc.toml`, the template, the label (a server dry run) and one restart of the node service.
   Check mode cannot install a package from a source that it did not add, and containerd lists
   `runsc` only after the restart. So the plan skips the install, the version read and the CRI
   reads.
2. Drain the node for the restart (`kubectl drain <node> --ignore-daemonsets
   --delete-emptydir-data`), run the play without `--check`, then uncordon the node.
3. Check: `kubectl get node -l node-restriction.kubernetes.io/gvisor=true` shows the node, and
   `sudo k3s crictl info` on the node lists the runtime `runsc`. The role does not start a sandbox.
   So, before a workload uses the RuntimeClass, start one canary pod with the RuntimeClass on the
   node: `uname -r` in it prints the kernel version that gVisor reports (`4.4.0`), not the host
   kernel.

## Move the pin

Read the release at <https://github.com/google/gvisor/releases> (tag `release-<version>`). Set
`gvisor_version` (`<date>.<point>`), then plan and run. The default `gvisor_release` is the date
part of the version. The apt suite `release` holds only the newest release, so the pin uses the
date suite. A date suite holds only the newest point release of its date: when gVisor publishes
`<date>.1`, the suite drops `<date>.0`. If the install cannot find `gvisor_version`, move
`gvisor_version` to the newer point release.

## Add a node

Add the host to the group of `target_hosts`, then plan and run. Do not add a host that is out of
service. Do not add the only k3s server: a restart of its node service stops the API server. A
server needs its own plan, its own review and `gvisor_allow_server: true`.

## Remove the runtime from a node

1. Make sure that no pod of the RuntimeClass runs on the node.
2. Remove the label (`kubectl label node <node> node-restriction.kubernetes.io/gvisor-`) and remove
   the host from the group of `target_hosts`.
3. Drain the node. Remove the template and restart the node service:
   `sudo rm /var/lib/rancher/k3s/agent/etc/containerd/config-v3.toml.tmpl && sudo systemctl restart k3s-agent`.
   Wait until the node is Ready, then uncordon it.
4. Run `sudo apt remove runsc`, and remove `/etc/apt/sources.list.d/gvisor.sources`,
   `/etc/apt/preferences.d/gvisor-runsc-pin` and `/etc/rancher/k3s/runsc.toml`.

## Limits

- Under `runsc`, the seccomp profile of the pod is not loaded in the sandbox (`oci-seccomp` stays
  off). The host filter of gVisor applies in its place.
- GPU pods cannot use the RuntimeClass: nvproxy is not configured.
- If a later k3s release finds `runsc` by itself, its base template writes the table of `runsc`,
  and the template of the role adds no second table, so containerd still starts. But the entry of
  k3s has no `ConfigPath`, so the runsc options of the role do not apply. So after each k3s upgrade,
  plan the play: its CRI check stops the run when the entry of `runsc` has no `ConfigPath`.
