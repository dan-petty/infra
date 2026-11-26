#!/usr/bin/env bash
# Tests of scripts/pr-title-scopes.sh, which gives the reusable workflow .github/workflows/pr-title.yml
# the scopes of the caller: the name after "scope/" of each scope/* label of its labels file, and ci,
# deps, docs, main and spec of every repository, each one time. Run it with
# `mise exec -- tests/test-pr-title-scopes.sh`.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
failures=0
cases=0

# expect NAME WANT_EXIT WANT_OUTPUT [LABELS]: write LABELS to a labels file (no file when LABELS is
# not given), run the script on it, and compare the exit code and the standard output with
# WANT_EXIT and WANT_OUTPUT. A case that must fail must also name the labels file on standard error.
expect() {
  local name="$1" want_exit="$2" want_output="$3" file="$work/$1/labels.yml" got_exit=0 got_output
  cases=$((cases + 1))
  mkdir -p "$work/$name"
  if [ "$#" -ge 4 ]; then
    printf '%s\n' "$4" >"$file"
  fi
  got_output="$("$root/scripts/pr-title-scopes.sh" "$file" 2>"$work/$name/stderr")" || got_exit=$?
  if [ "$got_exit" -ne "$want_exit" ]; then
    echo "FAIL $name: exit $got_exit, want $want_exit"
    sed 's/^/     /' "$work/$name/stderr"
    failures=$((failures + 1))
  elif [ "$got_output" != "$want_output" ]; then
    echo "FAIL $name: output $(printf '%q' "$got_output"), want $(printf '%q' "$want_output")"
    failures=$((failures + 1))
  elif [ "$want_exit" -ne 0 ] && ! grep -qF "$file" "$work/$name/stderr"; then
    echo "FAIL $name: the error does not name the labels file"
    sed 's/^/     /' "$work/$name/stderr"
    failures=$((failures + 1))
  else
    echo "ok   $name"
  fi
}

# The scopes of every repository: those that the repository template and the shared automation write.
common=$'ci\ndeps\ndocs\nmain\nspec'

expect scope-labels 0 $'k8s\ntf\n'"$common" '
- name: "type/feature"
  color: "0E8A16"
- name: "scope/k8s"
  color: "326CE5"
- name: "priority/p1-high"
  color: "D93F0B"
- name: "scope/tf"
  color: "7B42BC"'
expect no-scope-label 0 "$common" '
- name: "type/bug"
  color: "D73A4A"'
expect empty-list 0 "$common" '[]'
expect common-scope-labels 0 $'spec\nmain\nk8s\nci\ndeps\ndocs' '
- name: "scope/spec"
  color: "CFD3D7"
- name: "scope/main"
  color: "CFD3D7"
- name: "scope/k8s"
  color: "326CE5"
- name: "scope/ci"
  color: "1D76DB"'
expect scope-prefix-only 0 "$common" '
- name: "noscope/k8s"
  color: "326CE5"
- name: "type/scope/k8s"
  color: "326CE5"'
expect label-without-name 0 $'a\n'"$common" '
- color: "326CE5"
- name: 3
- name: "scope/a"'
expect no-labels-file 1 ""
expect not-a-list 1 "" 'name: "scope/k8s"'

echo "$((cases - failures)) of $cases cases passed"
[ "$failures" -eq 0 ]
