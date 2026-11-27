# ansible-common-firewall Specification

## Purpose

The UFW rules that the role `common` of the collection `dan_petty.infra` adds to a Debian k3s node, and the traffic that they log.

## Requirements

### Requirement: The IPv6 multicast of the pods is dropped with no log line
The role `common` SHALL add the UFW route rule `deny` from any source to `ff02::/16`, in and out on the bridge that `common_k3s_bridge_interface` names, with a comment and with no `log` option. The rule SHALL be in `ufw6-user-forward`, so that UFW drops the frames before `ufw6-after-logging-forward` logs them. The role SHALL keep `net.bridge.bridge-nf-call-ip6tables: 1` and the UFW log level.

#### Scenario: The task of the role
- **WHEN** `tests/test-ansible-collection.sh` runs from the repository root
- **THEN** the test play `common_ufw_route` prints `ok`: the task list of the role has one route rule, with `rule: deny`, both interfaces from `common_k3s_bridge_interface`, `to_ip: ff02::/16`, no source address, a comment, and no `log` or `logging` option

#### Scenario: The rule in UFW
- **WHEN** the role runs on a node with UFW and the default bridge
- **THEN** `ufw show added` lists `ufw route deny in on cni0 out on cni0 to ff02::/16 comment 'K3s pod IPv6 multicast'`, and a second run of the role reports no change

#### Scenario: A bridged frame writes no log line
- **WHEN** a pod on the bridge sends a router solicitation, an MLD report or a neighbor solicitation to `ff02::/16`, from `fe80::/10` or from `::`
- **THEN** the `DROP` rule of `ufw6-user-forward` counts the frame, and the `LOG` rule of `ufw6-after-logging-forward` does not

### Requirement: The bridge is a role variable
The role `common` SHALL take the bridge of the k3s pods from `common_k3s_bridge_interface`, with the default `cni0`, and SHALL declare it in `meta/argument_specs.yml`.

#### Scenario: The default and the argument spec
- **WHEN** `tests/test-ansible-collection.sh` runs from the repository root
- **THEN** the case `argument specs of the role common` prints `ok`, and the test play `common_ufw_route` finds `common_k3s_bridge_interface` equal to `cni0` with no play variable
