#!/usr/bin/env bash
# Tests of the check names of .github/workflows/ci.yml. GitHub names the check of a job that calls
# a reusable workflow "<job> / <called job>" when it runs, and "<job>" when it is skipped, so no
# ruleset can require such a job under one name. Each conditional job that calls a reusable
# workflow therefore has a job of its own that always reports one name, and fails when the call or
# the job changes did not succeed or get skipped. Run it with `mise exec -- tests/test-ci-check-names.sh`.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
workflow="$root/.github/workflows/ci.yml"
failures=0
cases=0

report() {
  cases=$((cases + 1))
  if [ "$1" = ok ]; then
    echo "ok   $2"
  else
    echo "FAIL $2"
    failures=$((failures + 1))
  fi
}

mapfile -t callers < <(yq -r '.jobs | to_entries | .[] | select(.value.uses != null and .value.if != null) | .key' "$workflow")

for caller in "${callers[@]}"; do
  export caller
  gate="$(yq -r '.jobs | to_entries | .[] | select(.value.uses == null and .value.if == "always()"
    and ([.value.needs] | flatten | contains([strenv(caller)]))) | .key' "$workflow" | head -n 1)"
  if [ -z "$gate" ]; then
    report FAIL "$caller: no job with if: always() needs it and reports its result"
    continue
  fi
  export gate
  if [ "$(yq -r '.jobs[strenv(gate)].name' "$workflow")" = "$(yq -r '.jobs[strenv(caller)].name' "$workflow")" ]; then
    report FAIL "$caller: $gate has the same name, so two checks share it"
  else
    report ok "$caller: $gate always reports the check"
  fi
  script="$(yq -r '.jobs[strenv(gate)].steps[0].run' "$workflow")"
  # CHANGES_RESULT CALL_RESULT WANT_EXIT: the results that GitHub gives the needed jobs.
  while read -r changes call want; do
    got=0
    CHANGES_RESULT="$changes" CALL_RESULT="$call" bash -euo pipefail -c "$script" >/dev/null 2>&1 || got=1
    if [ "$got" -eq "$want" ]; then
      report ok "$gate: changes=$changes call=$call exits $want"
    else
      report FAIL "$gate: changes=$changes call=$call exits $got, want $want"
    fi
  done <<'RESULTS'
success success 0
success skipped 0
skipped success 0
success failure 1
success cancelled 1
failure skipped 1
cancelled skipped 1
RESULTS
done

if [ "${#callers[@]}" -eq 0 ]; then
  report FAIL "no conditional job calls a reusable workflow, so this test checks nothing"
fi

echo "$((cases - failures)) of $cases cases passed"
[ "$failures" -eq 0 ]
