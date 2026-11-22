# Role cpu_tuning

The role `dan_petty.infra.cpu_tuning` sets some CPU settings of a BIOS from Linux. It installs
`/usr/local/sbin/cpu-tuning` and `cpu-tuning.service`, which run at each boot, and runs them now.
The play `dan_petty.infra.cpu_tuning` (`playbooks/cpu_tuning.yml`) runs the role only on a host
that sets one of the two variables below. A host with neither variable stays as it is. The role
does not reboot.

## Variables

`meta/argument_specs.yml` declares each variable. `ansible-doc -t role dan_petty.infra.cpu_tuning`
shows them. Set them in the `host_vars` of a host. Neither variable has a default.

| Variable | Content |
| --- | --- |
| `cpu_tuning_power_limits` | `pl1_w`, `pl2_w` and `tau_s`: the package power limits PL1 and PL2 in watts, and the time window of PL1 in seconds. The script writes them through `/sys/class/powercap/intel-rapl:0`. The kernel writes them to `MSR_PKG_POWER_LIMIT`, so this works only while the BIOS leaves that register unlocked (bit 63 is 0). |
| `cpu_tuning_idle_states_disabled` | `cpus` and `states`: the idle states, by name (`/sys/devices/system/cpu/cpu*/cpuidle/state*/name`), that the listed CPUs do not use. The CPUs stay on. The script enables each idle state that is not listed. |

The script disables an idle state by its name, not by its number, so a change of the state
numbering does not disable the wrong state. When the role runs with no variable, the script sets no
power limit and enables each idle state.

```yaml
cpu_tuning_power_limits:
  pl1_w: 65
  pl2_w: 120
  tau_s: 28
cpu_tuning_idle_states_disabled:
  cpus: [3, 11]
  states: [C6, C8]
```

Use the values of the CPU vendor for PL1, PL2 and the time window of the CPU.

## Run it

```sh
ansible-playbook dan_petty.infra.cpu_tuning -i <inventory> -e target_hosts=<group> --limit <host> --check --diff
ansible-playbook dan_petty.infra.cpu_tuning -i <inventory> -e target_hosts=<group> --limit <host>
```

Check on the host: `cat /sys/class/powercap/intel-rapl:0/constraint_{0,1}_power_limit_uw` and
`grep . /sys/devices/system/cpu/cpu<number>/cpuidle/state*/{name,disable}`.

A BIOS update, the memory speed (XMP) and the core voltage stay work for the BIOS.
