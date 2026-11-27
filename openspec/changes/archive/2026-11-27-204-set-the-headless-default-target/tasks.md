# Tasks

## 1. Behavior

- [x] 1.1 Add the test play `ansible/tests/common_default_target.yml` and the asserts of the new defaults in `ansible/tests/common_defaults.yml`, which fail on the base
  - Verification: `$ tests/test-ansible-collection.sh`
- [x] 1.2 Add `ansible/roles/common/tasks/default_target.yml`, include it from `tasks/main.yml`, and add the variables to `defaults/main.yml` and to the entry points `main` and `default_target` of `meta/argument_specs.yml`
  - Verification: `$ tests/test-ansible-collection.sh`
- [x] 1.3 Lint the collection with the production profile
  - Verification: `$ cd ansible && ../.venv/bin/ansible-lint`

## 2. Documents

- [x] 2.1 Describe the variables, the person decision of a reboot or `systemctl isolate`, and the start of one desktop session in `ansible/roles/common/README.md`, and name the default target in the row of `common` in `ansible/README.md`
  - Verification: `$ grep -n 'systemctl isolate' ansible/roles/common/README.md`

## Workflow follow-up

- Pending a person: after the release of this change, dan-petty/homelab#312 moves the pin of the collection, sets `common_default_target` and `common_display_manager_stop` for its hosts and groups, runs the role in check mode, and then applies it. A person decides on the reboot or `systemctl isolate` of each host.
- Pending a person: on a host where the display manager runs, the check mode run of the consumer shows the task "Stop the display manager" as changed. After the apply, `systemctl get-default` prints `multi-user.target` and `nvidia-smi` lists no Xorg process.
