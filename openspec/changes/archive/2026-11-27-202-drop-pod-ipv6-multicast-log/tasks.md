# Tasks

## 1. Behavior

- [x] 1.1 Write the test play `ansible/tests/common_ufw_route.yml`, which fails on the base
  - Verification: `$ tests/test-ansible-collection.sh`
- [x] 1.2 Add `common_k3s_bridge_interface` to `defaults/main.yml` and `meta/argument_specs.yml`, and the route rule task to `tasks/main.yml` of the role `common`
  - Verification: `$ tests/test-ansible-collection.sh`
- [x] 1.3 Lint the role and build the collection
  - Verification: `$ cd ansible && ../.venv/bin/ansible-lint && ../.venv/bin/ansible-galaxy collection build --output-path "$(mktemp -d)"`

## 2. Container check

- [x] 2.1 Run the route task against UFW in a container, as a repeatable manual check. Start a `debian:sid-slim` container with `--cap-add NET_ADMIN`, install `ufw`, `iptables`, `iproute2` and `ansible-core`, and give it community.general. Run the route task of the role two times with the defaults of the role: the first run reports `changed`, the second `ok`. Add a bridge `cni0` with two veth ports, run `ufw --force enable`, and set the free veth ends up. After 12 seconds, `ip6tables -L ufw6-user-forward -v -n -x` counts the frames on the `DROP` rule, and `ip6tables -L ufw6-after-logging-forward -v -n -x` counts 0 on the `LOG` rule.

## 3. Documents

- [x] 3.1 Name the variable, the rule and its reason in `ansible/roles/common/README.md`
  - Verification: `$ grep -n -e common_k3s_bridge_interface -e 'ff02::/16' ansible/roles/common/README.md`

## Workflow follow-up

- Pending a person: after the release, the consumer moves its pin and applies the role on its nodes (dan-petty/homelab#308). Then `sudo ufw show added` on a node lists `ufw route deny in on cni0 out on cni0 to ff02::/16 comment 'K3s pod IPv6 multicast'`, and 24 hours later `journalctl -k --since -24h | grep 'UFW BLOCK' | grep -c 'IN=cni0 OUT=cni0'` prints a number below 10.
