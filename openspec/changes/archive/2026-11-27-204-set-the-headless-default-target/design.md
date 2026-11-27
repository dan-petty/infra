# Design

## Decisions
- The change is opt-in. `common_default_target` has no default, as `nvidia_driver_branch` and `cpu_tuning_turbo` of this collection. A consumer sets it for a group or a host, and a host variable replaces a group variable.
- `common_display_manager_stop` (default `false`) asks for the stop. The link changes nothing until the next boot, but the stop ends a local desktop session at once, so a consumer asks for each one.
- `ansible.builtin.file` with `force: false` writes the link: the same link and the same refusals as `systemctl set-default` (proposal, "Feasibility").
- No `daemon-reload` and no handler. systemd reads the link at boot, and `systemctl get-default` reads it from the disk. A handler would also reload systemd on the machine of the test.
- The tasks have their own file and the argument spec entry point `default_target`. Thus `include_role` with `tasks_from: default_target` runs them alone, with the argument check, and without the package upgrade of the role.
- The test play puts the link into a temporary folder through `common_default_target_link`, so it needs no root. The one case that can reach the stop runs in check mode, so no test stops a service.

## Rejected alternatives
- Default `multi-user.target` (the hint of #204): the pin move of a consumer would change the boot of each host that runs the role, also of a host with a local desktop session, before the consumer sets an exception.
- Stop the display manager whenever the target is `multi-user.target` (the hint of #204): the stop ends a local desktop session at once, and a consumer can need the link with no stop.
- `force: true` (the hint of #204): it replaces a regular file at `/etc/systemd/system/default.target` and links a unit that does not exist. `systemctl set-default` of systemd 262 refuses both.
- `service_facts` with the condition `state == 'running'` (the hint of #204): the key `display-manager.service` comes from `list-unit-files` and holds the raw `ActiveState` `active`, so the condition never matches.
- Test only that `service_facts` has the key `display-manager.service`: on the GitHub runner `ubuntu-26.04`, the key has the status `not-found`, and the `systemd` module then fails with "Could not find the requested service display-manager.service" (the Ansible job of CI on that runner).
- `ansible.builtin.systemd` with only `name` to read the unit: ansible-core 2.22.0 refuses it (`required_one_of`).
- `ansible.builtin.command` with `systemctl set-default`: it does not run in check mode, and it needs a read task and `changed_when`.
- Disable the display manager or remove the desktop packages: `multi-user.target` does not want `display-manager.service`, so the default target alone keeps the display manager from the boot. #204 keeps the unit enabled and the packages installed, so a person can start one desktop session.
- A reboot or `systemctl isolate` in the role: it ends the sessions and the workloads of the host at a time that a person must choose.
