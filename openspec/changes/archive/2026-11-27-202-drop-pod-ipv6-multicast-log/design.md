# Design

## Decisions
- A UFW route rule with `rule: deny` drops the frames in `ufw6-user-forward`. The FORWARD chain reaches `ufw6-after-logging-forward`, which writes the `[UFW BLOCK]` line, only after `ufw6-before-forward` and its jump to `ufw6-user-forward`. The frames stay dropped, so the traffic of the pods does not change.
- The rule matches the destination `ff02::/16` and no source address. A pod sends the frames of its address check (duplicate address detection) from `::`, not from `fe80::/10`. An IPv6 destination makes UFW add the rule to `ip6tables` only.
- The task has no `log` option. That option adds a per-rule log; `logging` sets the global level. The global level stays `low`, so other blocked traffic is still logged.
- The variable `common_k3s_bridge_interface` names the bridge, with the default `cni0` of flannel in k3s. The role prefixes its k3s variables with `common_k3s_`.
- The task comes after the other UFW rule tasks and before the task that enables UFW, like the other rules of the role. UFW stores a rule while it is inactive and loads it at enable.
- The test play reads the task list of the source tree, as `cpu_tuning_script.yml` reads the template of its role, because a test play runs no task on a host. A container check runs the task against UFW (tasks.md).

## Rejected alternatives
- The source `fe80::/10`, as the issue proposed. In the container check, this rule drops 8 of 14 frames. The other 6 come from `::`: 2 neighbor solicitations (ICMPv6 type 135) and 4 MLD reports (type 143) that the kernel sends before the link-local address is ready. They still reach the policy and the `LOG` rule.
- Set `net.bridge.bridge-nf-call-ip6tables` to `0`. Then no `ip6tables` rule sees bridged IPv6, and pods on one node can reach each other on link-local IPv6 around NetworkPolicy, which an IPv4 k3s cluster enforces in `iptables` only. The consumer's live test of 2026-11-27 (#202) shows that UFW now drops the neighbor solicitation between two pods.
- A route `allow` rule. It lets the multicast of the pods pass, which the policy drops now, and NetworkPolicy does not see IPv6.
- `ufw logging off` or a lower level. It removes every other `[UFW BLOCK]` line too.
- A rule in `/etc/ufw/before6.rules`. The role would then own a copy of a configuration file of the `ufw` package and merge it at each package update. The module adds a user rule and is idempotent.
