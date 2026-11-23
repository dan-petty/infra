#!/usr/bin/env bash
# Tests of the Ansible collection dan_petty.infra (ansible/). The script builds the collection and
# installs the archive into a temporary collections path, as a consumer does. Then, with the example
# inventory ansible/tests/inventory/example, it:
#   - checks that the example inventory has the groups of the test plays,
#   - checks the syntax of each play of ansible/playbooks/, by the full name of the play,
#   - reads the argument specs of each role of ansible/roles/ with ansible-doc,
#   - runs the play cpu_tuning on hosts that have no CPU settings: the play skips each host,
#   - runs each test play of ansible/tests/. Each test play checks its own result.
# The hosts of the example inventory have RFC 5737 addresses, so a task that runs on a host fails.
# Run it from the repository root after `uv sync --frozen`: tests/test-ansible-collection.sh.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
failures=0
cases=0

# The Python tools of uv.lock, and an Ansible home, temp folder and collections path of this run only.
export PATH="$root/.venv/bin:$PATH"
export ANSIBLE_HOME="$work/home"
export ANSIBLE_LOCAL_TEMP="$work/tmp"
export ANSIBLE_COLLECTIONS_PATH="$work/collections:${ANSIBLE_COLLECTIONS_PATH:-$HOME/.ansible/collections}"
export ANSIBLE_NOCOLOR=1
export ANSIBLE_TIMEOUT=5
inventory="$root/ansible/tests/inventory/example"

# check NAME COMMAND...: run COMMAND, and count a non-zero exit as a failure with its output.
check() {
  local name="$1"
  shift
  cases=$((cases + 1))
  if "$@" >"$work/check.log" 2>&1; then
    echo "ok   $name"
  else
    echo "FAIL $name"
    sed 's/^/     /' "$work/check.log"
    failures=$((failures + 1))
  fi
}

# has_groups GROUP...: the graph of the example inventory lists each GROUP.
has_groups() {
  local graph group
  graph="$(ansible-inventory -i "$inventory" --graph)"
  for group in "$@"; do
    grep -q -- "@$group:" <<<"$graph" || {
      echo "The example inventory has no group $group."
      return 1
    }
  done
}

# skips_each_host COMMAND...: COMMAND succeeds, and its recap shows no host with a change or a run task.
skips_each_host() {
  local output
  output="$("$@")" || {
    echo "$output"
    return 1
  }
  if ! grep -q 'skipped=' <<<"$output" || grep -qE '(changed|ok)=[1-9]' <<<"$output"; then
    echo "$output"
    echo "The play ran a task on a host that has no CPU settings."
    return 1
  fi
}

# has_target_hosts PLAY: the play takes its hosts from target_hosts and has no literal host or group.
has_target_hosts() {
  local play="$1"
  grep -qE '^[[:space:]]*hosts:[[:space:]]*["'\'']?\{\{[[:space:]]*target_hosts[[:space:]]*\}\}["'\'']?[[:space:]]*$' "$play" || {
    echo "The play $play does not take hosts from target_hosts."
    return 1
  }
}

check "build the collection" ansible-galaxy collection build "$root/ansible" --output-path "$work/build"
archive="$(find "$work/build" -name 'dan_petty-infra-*.tar.gz' -print -quit 2>/dev/null)"
check "install the archive" ansible-galaxy collection install "${archive:-no-archive}" -p "$work/collections"
check "groups of the example inventory" has_groups k3s_server gvisor_nodes gpu_nodes

for play in "$root"/ansible/playbooks/*.yml; do
  name="$(basename "$play" .yml)"
  check "syntax of the play $name" \
    ansible-playbook --syntax-check -i "$inventory" -e target_hosts=all "dan_petty.infra.$name"
  check "host variable of $name" has_target_hosts "$play"
done

for role in "$root"/ansible/roles/*/; do
  name="$(basename "$role")"
  check "argument specs of the role $name" ansible-doc -t role "dan_petty.infra.$name"
done

check "the play cpu_tuning skips a host with no CPU settings" \
  skips_each_host ansible-playbook -i "$inventory" -e target_hosts=all dan_petty.infra.cpu_tuning

for test in "$root"/ansible/tests/*.yml; do
  check "test play $(basename "$test" .yml)" ansible-playbook -i "$inventory" "$test"
done

echo "$((cases - failures)) of $cases cases passed"
[ "$failures" -eq 0 ]
