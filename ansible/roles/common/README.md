# Role common

The role `dan_petty.infra.common` provisions the baseline configuration of a Debian k3s node. It:

- Configures Debian APT repositories in DEB822 format for the specified suite.
- Configures GRUB for unattended headless booting.
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
