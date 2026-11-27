# Role common

The role `dan_petty.infra.common` provisions the baseline configuration of a Debian k3s node. It:

- Configures Debian APT repositories in DEB822 format for the specified suite.
- Configures GRUB for unattended headless booting.
- Sets the systemd default target, and stops a running display manager, only on a host that sets the variables of the default target ("Default target").
- Installs baseline system packages and provisions the dedicated automation user.
- Loads and persists required kernel modules for K8s and containerd.
- Applies sysctl networking parameters.
- Disables swap memory.
- Enables and configures UFW firewall, allowing OpenSSH, the k3s cluster CIDRs, and any configured site CIDRs.

## Variables

`meta/argument_specs.yml` declares each variable. `ansible-doc -t role dan_petty.infra.common` shows them.

| Variable | Default | Content |
| --- | --- | --- |
| `common_apt_suite` | None. Required. | The Debian suite (e.g. `bookworm`, `trixie`, `sid`) for APT repositories. |
| `common_ufw_allowed_cidrs` | `[]` | List of site CIDR blocks allowed through UFW. |
| `common_k3s_pod_cidr` | `10.42.0.0/16` | The k3s default pod CIDR block. |
| `common_k3s_service_cidr` | `10.43.0.0/16` | The k3s default service CIDR block. |
| `common_base_packages` | Standard system packages list | List of system packages to install. |
| `common_kernel_modules` | `overlay`, `br_netfilter`, `ip_tables`, `iptable_nat`, `iptable_filter` | Kernel modules required for K8s. |
| `common_sysctl_params` | Standard sysctl map | Sysctl key-value pairs applied to `/etc/sysctl.d/99-k3s-cri.conf`. |
| `common_automation_user` | `ansible` | Dedicated automation username. |
| `common_automation_user_shell` | `/bin/bash` | Shell for the automation user. |
| `common_automation_user_groups` | `["sudo"]` | Supplementary groups for the automation user. |
| `common_automation_user_pubkeys` | `[]` | List of SSH public keys for the automation user. |
| `common_system_upgrade_on_bootstrap` | `true` | Whether to run system package upgrades. |
| `common_system_upgrade_type` | `dist` | Package upgrade type (`dist` or `safe`). |
| `common_system_upgrade_autoremove` | `true` | Whether to autoremove orphaned packages. |
| `common_system_upgrade_clean` | `true` | Whether to clean APT cache archives. |
| `common_default_target` | None. Not set means no change. | The systemd default target: `multi-user.target` or `graphical.target` ("Default target"). |
| `common_display_manager_stop` | `false` | Whether to stop a running display manager when `common_default_target` is `multi-user.target`. |
| `common_default_target_link` | `/etc/systemd/system/default.target` | The link that sets the default target. A test sets a temporary path. |

## Default target

The role changes the systemd default target only on a host that sets `common_default_target`.
Set it for each host or group in the inventory of the consumer:

- `multi-user.target`: the host boots with no display manager and no X server.
- `graphical.target`: the host boots with the display manager.

The role writes the link `/etc/systemd/system/default.target`, the same link that
`systemctl set-default` writes. `systemctl get-default` shows the new target at once, and the
target takes effect at the next boot. The role does not reboot the host and does not run
`systemctl isolate`. A person decides when to reboot the host, or runs
`sudo systemctl isolate multi-user.target`.

The role stops a running display manager only when `common_display_manager_stop` is `true` and
`common_default_target` is `multi-user.target`. The stop ends each local desktop session of the
host: do not set it for a host where a person uses the desktop. A host with no display manager
skips the stop. The role keeps the display manager enabled and the desktop packages installed. To
start one desktop session on a headless host, run `sudo systemctl start display-manager`.

```yaml
# group_vars/<group>.yml
common_default_target: multi-user.target
common_display_manager_stop: true

# host_vars/<desktop-host>.yml: a host with a local desktop session
common_default_target: graphical.target
common_display_manager_stop: false
```

To run only these tasks, without the package upgrade of the role, use `tasks_from: default_target`
with no `.yml`. The argument check of the role then reads the entry point `default_target`:

```yaml
- name: Set the default target
  hosts: "{{ target_hosts }}"
  become: true
  tasks:
    - name: Run the default target tasks of the common role
      ansible.builtin.include_role:
        name: dan_petty.infra.common
        tasks_from: default_target
```

## Run the role

```yaml
- name: Apply common configuration
  hosts: "{{ target_hosts }}"
  become: true
  roles:
    - role: dan_petty.infra.common
      vars:
        common_apt_suite: bookworm
        common_ufw_allowed_cidrs:
          - 192.0.2.0/24
```
