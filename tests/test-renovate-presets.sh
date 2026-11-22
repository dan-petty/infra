#!/usr/bin/env bash
# Tests of the Renovate presets of renovate/ and of the Renovate config .github/renovate.json.
# - The config validator of Renovate checks each file in strict mode.
# - The fixture tests/renovate/ is a consumer repository: it holds one pin of infra in each consumer
#   form (README.md, "Pin a release") and a CloudNativePG Cluster. A consumer extends
#   github>dan-petty/infra//renovate/base and github>dan-petty/infra//renovate/k8s. The local
#   platform of Renovate does not resolve a preset of a repository, so the test merges the two
#   presets into one config, as Renovate merges the presets of extends: the packageRules and the
#   customManagers of k8s.json come after those of base.json, and k8s.json sets each other key.
# - Renovate extracts the dependencies of a copy of the fixture with that config
#   (`--platform=local --dry-run=extract` reads the files of the working tree, looks up no release
#   and opens no pull request). The test checks that Renovate reads each pin of infra, at a release
#   tag, with the datasource github-tags or git-tags, and the image of the Cluster.
# Run it with `mise exec -- tests/test-renovate-presets.sh`. npx installs the Renovate release of
# RENOVATE_VERSION with the Node of mise.toml, and runs no install script of a package.
set -euo pipefail

# renovate: datasource=npm depName=renovate
RENOVATE_VERSION=44.257.9

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
failures=0
cases=0
export npm_config_ignore_scripts=true npm_config_update_notifier=false npm_config_audit=false \
  npm_config_fund=false RENOVATE_BASE_DIR="$work/renovate"

renovate() {
  npx --yes --package "renovate@$RENOVATE_VERSION" -- "$@"
}

# The config validator, in strict mode: a config that needs a migration also fails.
cases=$((cases + 1))
if (cd "$root" && renovate renovate-config-validator --strict renovate/base.json renovate/k8s.json \
  .github/renovate.json) >"$work/validate.log" 2>&1; then
  echo "ok   renovate-config-validator"
else
  echo "FAIL renovate-config-validator"
  sed 's/^/     /' "$work/validate.log"
  failures=$((failures + 1))
fi

# The consumer repository: a copy of the fixture, with the merged presets as its renovate.json. The
# local platform lists the files of the repository with git ls-files.
mkdir "$work/repo"
cp -R "$root/tests/renovate/." "$work/repo/"
if ! jq -n --slurpfile base "$root/renovate/base.json" --slurpfile k8s "$root/renovate/k8s.json" '
    $base[0] * $k8s[0]
    | .packageRules = ($base[0].packageRules // []) + ($k8s[0].packageRules // [])
    | .customManagers = ($base[0].customManagers // []) + ($k8s[0].customManagers // [])
    | del(.description)' >"$work/repo/renovate.json" 2>"$work/merge.log"; then
  echo "FAIL merge renovate/base.json and renovate/k8s.json"
  sed 's/^/     /' "$work/merge.log"
  echo "0 of $((cases + 1)) cases passed"
  exit 1
fi
git -C "$work/repo" init --quiet
git -C "$work/repo" add --all

# The extract. The JSON log has one record with the field packageFiles: the dependencies of each
# manager in each file.
cases=$((cases + 1))
if (cd "$work/repo" && LOG_FORMAT=json LOG_LEVEL=info renovate renovate --platform=local \
  --dry-run=extract) >"$work/extract.log" 2>&1; then
  echo "ok   renovate --platform=local --dry-run=extract"
else
  echo "FAIL renovate --platform=local --dry-run=extract"
  tail -n 20 "$work/extract.log" | sed 's/^/     /'
  failures=$((failures + 1))
fi
grep '^{' "$work/extract.log" | jq -c '
  select(.packageFiles) | .packageFiles | to_entries[] | .key as $manager | .value[]
  | .packageFile as $file | .deps[]
  | {manager: $manager, file: $file, depName, packageName, datasource, currentValue, skipReason}' \
  >"$work/deps.jsonl"

# check NAME FILTER TEST: exactly one dependency of the extract matches the jq filter FILTER, and
# that dependency passes the jq test TEST.
check() {
  local name="$1" filter="$2" test="$3" deps
  cases=$((cases + 1))
  deps="$(jq -c "select($filter)" "$work/deps.jsonl")"
  if [ "$(printf '%s' "$deps" | grep -c .)" -ne 1 ]; then
    echo "FAIL $name: want one dependency, got: ${deps:-none}"
    failures=$((failures + 1))
  elif ! printf '%s' "$deps" | jq -e "$test" >/dev/null; then
    echo "FAIL $name: got: $deps"
    failures=$((failures + 1))
  else
    echo "ok   $name: $deps"
  fi
}

# expect MANAGER: MANAGER reads one pin of infra, at a release tag vX.Y.Z, with the datasource
# github-tags or git-tags. Without a token, Renovate marks a github-tags dependency with the skip
# reason github-token-required; each other skip reason tells that the manager cannot read the pin.
infra='[.depName, .packageName] | any(. != null and test("github\\.com/dan-petty/infra|^dan-petty/infra$"))'
pin='(.datasource == "github-tags" or .datasource == "git-tags")
  and (.currentValue | test("^v[0-9]+\\.[0-9]+\\.[0-9]+$"))
  and (.skipReason == null or .skipReason == "github-token-required")'
expect() {
  check "$1: the pin of infra" ".manager == \"$1\" and ($infra)" "$pin"
}

expect kustomize
expect terraform
expect ansible-galaxy
expect argocd
expect github-actions

# The CloudNativePG custom manager reads the image of spec.imageName of the Cluster, and not the
# deeper imageName field of the Helm values.
check "custom.regex: the image of the CloudNativePG Cluster" '.manager == "regex"' \
  '.file == "k8s/cluster.yaml" and .datasource == "docker"
  and .depName == "ghcr.io/cloudnative-pg/postgresql" and .currentValue == "17.5"'

echo "$((cases - failures)) of $cases cases passed"
[ "$failures" -eq 0 ]
