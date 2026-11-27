# Proposal: the role common sets the headless default target

## Why
The role `common` sets GRUB for headless boots, but no task sets the systemd default target (#204). A Debian install with a desktop links `default.target` to `graphical.target`, which wants `display-manager.service`. So the display manager starts an X server at each boot, and with the NVIDIA driver the X server opens each GPU.

A consumer (dan-petty/homelab#312) wants its k3s nodes to boot with no display manager. A host of a consumer can also have a local desktop session. So each host or group asks for the change in the inventory, and the stop of a running display manager needs its own variable.

## What Changes
- The new task file `ansible/roles/common/tasks/default_target.yml` runs after the GRUB tasks of `tasks/main.yml`:
  - When the host sets `common_default_target`, it links `/etc/systemd/system/default.target` to `/usr/lib/systemd/system/<common_default_target>` with `ansible.builtin.file` (`state: link`, `force: false`).
  - When `common_display_manager_stop` is true, the target is `multi-user.target` and `ansible.builtin.service_facts` lists `display-manager.service` with a status other than `not-found`, it stops that unit with `ansible.builtin.systemd`. The unit stays enabled.
- New variables in `defaults/main.yml`, `meta/argument_specs.yml` and the role README: `common_default_target` (no default, choices `multi-user.target` and `graphical.target`), `common_display_manager_stop` (default `false`) and `common_default_target_link` (default `/etc/systemd/system/default.target`).
- `meta/argument_specs.yml` gets the entry point `default_target`, so `include_role` with `tasks_from: default_target` runs these tasks alone with the argument check.
- The section "Default target" of the role README says what the variables do, that a reboot or `systemctl isolate` is a decision of a person, and how a person starts one desktop session.
- The new test play `ansible/tests/common_default_target.yml` and new asserts in `ansible/tests/common_defaults.yml`.

## Capabilities
- `common-default-target` (new): the systemd default target and the stop of the display manager that the role `common` applies.

## Impact
A host that sets no new variable gets no change, so the pin move of a consumer changes no host. The consumer sets the variables in its inventory and applies the role. The new target takes effect at the next boot. The role does not reboot a host and does not run `systemctl isolate`. The release is a minor version (`feat`). The change fits one pull request.

## Feasibility
Confirmed on 2026-11-27:
- ansible-core 2.22.0 (`uv.lock`): `ansible.builtin.systemd` has no option for the default target, and it needs one of `state`, `enabled`, `masked`, `daemon_reload` or `daemon_reexec` (`required_one_of` in `modules/systemd_service.py`), so it cannot only read a unit. `ensure_symlink` of `modules/file.py` replaces a link with another target, reports the change in check mode with no write, and with `force: false` refuses a missing source and a regular file at the path.
- systemd 262, `systemctl --root=<temporary folder> set-default graphical.target`: it writes the link `/etc/systemd/system/default.target` to `/usr/lib/systemd/system/graphical.target`. It refuses a unit that does not exist, and a regular file at the link path.
- systemd 262: `graphical.target` has `Wants=display-manager.service`, and `multi-user.target` does not. `list-unit-files` lists an enabled display manager alias as `display-manager.service alias`. `service_facts` adds that line with the raw `ActiveState`, such as `active`, as its `state`. A test for `state == 'running'` thus never matches the alias. On a host with no display manager, `list-units --all` can list `display-manager.service` with the status `not-found`, because `graphical.target` wants it (the GitHub runner `ubuntu-26.04` does). So the stop task tests the status, as the example of `service_facts` does, and the `systemd` module stops the unit only when it runs.
- `include_role` takes the entry point of the argument spec from the raw `tasks_from` value (`playbook/role/__init__.py`), so the entry point `default_target` needs `tasks_from: default_target` with no `.yml`.

## Existing Tool Considered
ansible-core, already pinned in `pyproject.toml`: `ansible.builtin.file` writes the link, `ansible.builtin.service_facts` finds the display manager and `ansible.builtin.systemd` stops it. No module and no maintained collection sets the default target (the alternatives check of #204). The change adds three tasks and no custom code. It deletes no code.
