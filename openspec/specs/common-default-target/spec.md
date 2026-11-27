# common-default-target Specification

## Purpose

The systemd default target, and the stop of the display manager, that the Ansible role `dan_petty.infra.common` applies to a host that asks for them.

## Requirements

### Requirement: The role changes the default target only on a host that sets it
The role `common` SHALL link `common_default_target_link` to `/usr/lib/systemd/system/<common_default_target>` when the host sets `common_default_target`, and SHALL write no link when the host does not set it. Its defaults SHALL leave `common_default_target` not set and `common_display_manager_stop` false.

#### Scenario: The defaults
- **WHEN** the test play `ansible/tests/common_defaults.yml` imports the role with no task
- **THEN** `common_default_target` is not defined, `common_display_manager_stop` is false and `common_default_target_link` is `/etc/systemd/system/default.target`

#### Scenario: No target set
- **WHEN** the test play `ansible/tests/common_default_target.yml` runs the tasks `default_target` with no `common_default_target`
- **THEN** the link task skips and the link path does not exist

#### Scenario: A target set
- **WHEN** the test play runs the tasks `default_target` with `common_default_target: graphical.target`, and then a second time
- **THEN** the first run reports a change, the link points at `/usr/lib/systemd/system/graphical.target`, and the second run reports no change

#### Scenario: Check mode
- **WHEN** the test play runs the tasks `default_target` in check mode with `multi-user.target` over a link to `graphical.target`
- **THEN** the link task reports a change, and the link still points at `/usr/lib/systemd/system/graphical.target`

### Requirement: The role stops the display manager only when the host asks for it
The role `common` SHALL stop `display-manager.service` only when `common_display_manager_stop` is true, `common_default_target` is `multi-user.target` and `ansible.builtin.service_facts` lists the unit. The role SHALL keep the unit enabled.

#### Scenario: No stop asked
- **WHEN** the test play runs the tasks `default_target` with `multi-user.target` and the default `common_display_manager_stop`
- **THEN** the stop task skips

#### Scenario: The graphical target
- **WHEN** the test play runs the tasks `default_target` with `graphical.target` and `common_display_manager_stop: true`
- **THEN** the stop task skips

#### Scenario: A host where the display manager runs
- **WHEN** a person runs the role in check mode with `multi-user.target` and `common_display_manager_stop: true` on a host where `display-manager.service` is active
- **THEN** the live check shows the task "Stop the display manager" as changed

### Requirement: The argument check refuses a target that is not a choice
The entry points `main` and `default_target` of the role `common` SHALL accept only `multi-user.target` and `graphical.target` for `common_default_target`.

#### Scenario: A target that is not a choice
- **WHEN** the test play runs the tasks `default_target` with `common_default_target: multi-user`
- **THEN** the argument check stops the run before the first task and names `common_default_target`
