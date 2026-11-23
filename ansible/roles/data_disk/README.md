# Role data_disk

The role `dan_petty.infra.data_disk` formats and mounts a dedicated data block device (such as an NVMe drive). It:

- Checks if the specified block device exists and fails cleanly if absent.
- Formats the block device with the specified filesystem (default `ext4`) without overwriting existing data (`force: false`).
- Creates the mount point directory and configures persistent mounting in `/etc/fstab`.

## Variables

`meta/argument_specs.yml` declares each variable. `ansible-doc -t role dan_petty.infra.data_disk` shows them.

| Variable | Default | Content |
| --- | --- | --- |
| `data_disk_device` | None. Required. | Path to target block device (such as an NVMe device). |
| `data_disk_mount_path` | None. Required. | Path to directory mount point. |
| `data_disk_filesystem` | `ext4` | Target filesystem type. |
| `data_disk_mount_options` | `defaults,noatime,discard` | Mount options in `/etc/fstab`. |

## Run the role

```yaml
- name: Mount NVMe data drive
  hosts: "{{ target_hosts }}"
  become: true
  roles:
    - role: dan_petty.infra.data_disk
      vars:
        data_disk_device: "<device-path>"
        data_disk_mount_path: /mnt/storage
```
