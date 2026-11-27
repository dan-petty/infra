# Proposal: drop the IPv6 multicast of k3s pods on their bridge with no log line

## Why
The role `common` sets `net.bridge.bridge-nf-call-ip6tables: 1` and enables UFW, whose routed policy is `DROP` and whose log level is `low` by default (#202). So each IPv6 frame that a pod sends across the flannel bridge `cni0` goes through the `ip6tables` FORWARD chain. The pods send link-local multicast to `ff02::/16` (router solicitations, MLD reports and neighbor solicitations). No rule matches these frames, so UFW drops them and writes a `[UFW BLOCK]` line for each one. A consumer counts thousands of these lines a day on each node (dan-petty/homelab#308). They fill the UFW log limit and hide other kernel messages.

## What Changes
- The role adds the route rule `ufw route deny in on <bridge> out on <bridge> to ff02::/16` with the module `community.general.ufw`, with no `log` option.
- The new variable `common_k3s_bridge_interface` (default `cni0`) names the bridge. `defaults/main.yml`, `meta/argument_specs.yml` and the role README name it.
- The role README tells why the rule drops the frames with no log line.
- The frames stay dropped, as they were before. `net.bridge.bridge-nf-call-ip6tables` and the UFW log level do not change.
- The test play `ansible/tests/common_ufw_route.yml` checks the task and the default.

## Capabilities
- `ansible-common-firewall` (new): the UFW rules that the role `common` adds.

## Impact
A consumer gets the rule when its pin of the collection moves to the release that holds this change, and the role runs on its nodes. The rule adds one IPv6 route rule and no IPv4 rule. The change fits one pull request.

## Feasibility
Confirmed on 2026-11-27 in a throwaway `debian:sid-slim` container with its own network namespace, UFW 0.36.2, ansible-core 2.22.0 and community.general 14.0.1:

- The route task of the role runs two times: `changed`, then `ok`. `ufw show added` prints `ufw route deny in on cni0 out on cni0 to ff02::/16 comment 'K3s pod IPv6 multicast'`.
- `ip6tables -S FORWARD` gives the order `ufw6-before-logging-forward`, `ufw6-before-forward`, `ufw6-after-forward`, `ufw6-after-logging-forward`. The last rule of `ufw6-before-forward` is `-j ufw6-user-forward`, which `/lib/ufw/ufw-init-functions` adds. `ufw-framework(8)` says: "Rules are evaluated as follows: before.rules first, user.rules next, and after.rules last". `iptables(8)` says: "DROP means to drop the packet on the floor", so no later chain sees the packet.
- A bridge `cni0` with two veth ports gets the router solicitations and MLD reports of the kernel when the ports come up. With no route rule, the policy drops 14 frames and the `LOG` rule of `ufw6-after-logging-forward` counts 10. With the rule, the rule drops 14 frames, and the policy and the `LOG` rule count 0.
- `ufw(8)`: the level `low` "logs all blocked packets not matching the defined policy (with rate limiting), as well as packets matching logged rules". The rule has no `log` option, so UFW writes no line for it.

## Existing Tool Considered
UFW route rules and the module `community.general.ufw` (GPL-3.0, maintained), which the role already uses for its other UFW rules. Its options `route`, `rule`, `interface_in`, `interface_out`, `to_ip` and `comment` give the rule in one task, and the module is idempotent. No code is built. This change deletes no code.
