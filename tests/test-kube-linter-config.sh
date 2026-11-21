#!/usr/bin/env bash
# Tests of the shared kube-linter config .kube-linter.yaml: the custom check pvc-prune-protection
# refuses a PersistentVolumeClaim that Argo CD can prune or delete, and admits one with the sync
# options Prune=false and Delete=false. Run it with `mise exec -- tests/test-kube-linter-config.sh`.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
failures=0
cases=0

# expect WANT NAME SYNC_OPTIONS: lint a PersistentVolumeClaim with the annotation
# argocd.argoproj.io/sync-options set to SYNC_OPTIONS (no annotation when it is empty), and compare
# the exit code of kube-linter with WANT.
expect() {
  local want="$1" name="$2" options="$3" got=0
  cases=$((cases + 1))
  {
    printf 'apiVersion: v1\nkind: PersistentVolumeClaim\nmetadata:\n  name: data\n'
    if [ -n "$options" ]; then
      printf '  annotations:\n    argocd.argoproj.io/sync-options: %s\n' "$options"
    fi
    printf 'spec:\n  accessModes: [ReadWriteOnce]\n  resources:\n    requests:\n      storage: 1Gi\n'
  } >"$work/$name.yaml"
  kube-linter lint --config "$root/.kube-linter.yaml" "$work/$name.yaml" >"$work/$name.log" 2>&1 || got=$?
  if [ "$got" -ne "$want" ]; then
    echo "FAIL $name: exit $got, want $want"
    sed 's/^/     /' "$work/$name.log"
    failures=$((failures + 1))
  elif [ "$want" -ne 0 ] && ! grep -q 'pvc-prune-protection' "$work/$name.log"; then
    echo "FAIL $name: the output names no pvc-prune-protection finding"
    failures=$((failures + 1))
  else
    echo "ok   $name"
  fi
}

expect 1 no-annotation ""
expect 1 prune-only "Prune=false"
expect 0 prune-and-delete "Prune=false,Delete=false"
expect 0 delete-and-prune "ServerSideApply=true,Delete=false,Prune=false"

echo "$((cases - failures)) of $cases cases passed"
[ "$failures" -eq 0 ]
