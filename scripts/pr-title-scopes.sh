#!/usr/bin/env bash
# The scopes of the pull request title check of the reusable workflow .github/workflows/pr-title.yml.
# The script reads a labels file in the form of .github/labels.yml (a list of labels, each with a
# name), and prints, one on each line, the name after "scope/" of each scope/* label, and then
# `main`, the scope of the release pull request of release-please. Each scope comes one time. A
# local run gives the same list as the workflow:
#
#   mise exec -- scripts/pr-title-scopes.sh .github/labels.yml
set -euo pipefail

if [ "$#" -ne 1 ]; then
  echo "Usage: scripts/pr-title-scopes.sh <labels file>" >&2
  exit 2
fi
file="$1"

if [ ! -f "$file" ]; then
  echo "pr-title-scopes: the labels file $file does not exist. Add the labels of the repository to it." >&2
  exit 1
fi
if [ "$(yq 'type' "$file")" != '!!seq' ]; then
  echo "pr-title-scopes: the labels file $file holds no list of labels." >&2
  exit 1
fi

# A name that is not a string is no label name, so it gives no scope.
yq '[(.[] | .name | select(tag == "!!str" and test("^scope/")) | sub("^scope/"; "")), "main"] | unique | .[]' "$file"
