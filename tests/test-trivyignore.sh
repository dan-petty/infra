#!/usr/bin/env bash
# Tests of trivy ignore file expiry behavior: proves that trivy config suppresses an unexpired entry
# and reports the finding once an entry has expired. Run it with `mise exec -- tests/test-trivyignore.sh`.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
failures=0
cases=0

# expect WANT NAME EXPIRED_AT: scan tf/examples/aws with an ignorefile that ignores AWS-0104 with
# expired_at set to EXPIRED_AT, and compare the exit code of trivy config with WANT.
expect() {
  local want="$1" name="$2" expired_at="$3" got=0
  cases=$((cases + 1))
  cat <<EOF >"$work/$name.yaml"
misconfigurations:
  - id: AWS-0104
    paths:
      - terraform-aws-modules/eks/aws/node_groups.tf
    statement: Test entry for $name
    expired_at: $expired_at
EOF
  trivy config --exit-code 1 --severity HIGH,CRITICAL --ignorefile "$work/$name.yaml" \
    --skip-dirs '**/.terraform' --tf-vars "$root/tf/examples/aws/aws.tfvars.example" \
    "$root/tf/examples/aws" >"$work/$name.log" 2>&1 || got=$?
  if [ "$got" -ne "$want" ]; then
    echo "FAIL $name: exit $got, want $want"
    sed 's/^/     /' "$work/$name.log"
    failures=$((failures + 1))
  elif [ "$want" -ne 0 ] && ! grep -q 'AWS-0104' "$work/$name.log"; then
    echo "FAIL $name: the output names no AWS-0104 finding"
    failures=$((failures + 1))
  else
    echo "ok   $name"
  fi
}

expect 0 unexpired "2099-01-01"
expect 1 expired "2020-01-01"

echo "$((cases - failures)) of $cases cases passed"
[ "$failures" -eq 0 ]
