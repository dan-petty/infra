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
# - Renovate looks up the releases of each pin of infra (`--dry-run=lookup`). The extract does not
#   apply the packageRules, so only the lookup proves a rule that changes the name that a lookup
#   reads. The test checks that each lookup gets the repository https://github.com/dan-petty/infra
#   with no warning. The datasource github-tags reads the GitHub API, which needs a token: set
#   RENOVATE_GITHUB_COM_TOKEN to a token that can read public repositories. Without a token, the
#   test skips the lookup; in CI (CI=true) the lookup is necessary.
# Run it with `mise exec -- tests/test-renovate-presets.sh`. npx installs the Renovate release of
# RENOVATE_VERSION with the Node of mise.toml, and runs no install script of a package.
set -euo pipefail

# renovate: datasource=npm depName=renovate
RENOVATE_VERSION=45.1.0

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

# The automerge configuration of base.json covers each update after all checks pass (#52).
cases=$((cases + 1))
if jq -e '.automerge == true and (.packageRules[] | select(.automerge == true) | (.matchUpdateTypes // []) == [])' \
  "$root/renovate/base.json" >/dev/null 2>&1; then
  echo "ok   renovate/base.json: automerge is enabled for all updates"
else
  echo "FAIL renovate/base.json: automerge for all updates is missing"
  failures=$((failures + 1))
fi

# The rangeStrategy of base.json is bump, so version ranges update with lock files (#79).
cases=$((cases + 1))
if jq -e '.rangeStrategy == "bump"' "$root/renovate/base.json" >/dev/null 2>&1; then
  echo "ok   renovate/base.json: rangeStrategy is bump"
else
  echo "FAIL renovate/base.json: rangeStrategy is bump is missing"
  failures=$((failures + 1))
fi

# The abandonmentThreshold of base.json is 18 months (#122).
cases=$((cases + 1))
if jq -e '.abandonmentThreshold == "18 months"' "$root/renovate/base.json" >/dev/null 2>&1; then
  echo "ok   renovate/base.json: abandonmentThreshold is 18 months"
else
  echo "FAIL renovate/base.json: abandonmentThreshold is 18 months is missing"
  failures=$((failures + 1))
fi

# base.json requests dan-petty as a reviewer on each Renovate pull request (#145).
cases=$((cases + 1))
if jq -e '
  ((.vulnerabilityAlerts.reviewers // []) | index("dan-petty") != null)
  and ((.lockFileMaintenance.reviewers // []) | index("dan-petty") != null)
  and any(.packageRules[]; (.matchPackageNames // []) == ["*"] and ((.reviewers // []) | index("dan-petty") != null))
' "$root/renovate/base.json" >/dev/null 2>&1; then
  echo "ok   renovate/base.json: reviewers includes dan-petty"
else
  echo "FAIL renovate/base.json: dan-petty reviewer is missing"
  failures=$((failures + 1))
fi

# The consumer repository: a copy of the fixture, with the merged presets as its renovate.json. The
# local platform lists the files of the repository with git ls-files.
# Each manager names infra in its own form, and the title takes that name. Each form gets a topic
# that starts with dan-petty/infra, from a rule after each other rule that sets a topic, so that the
# title stays within the 60 characters of the title check.
cases=$((cases + 1))
if jq -e '
  .packageRules as $rules
  | [range(0; $rules | length) | select($rules[.].commitMessageTopic != null)] as $topics
  | [$topics[] | select($rules[.].commitMessageTopic | startswith("dan-petty/infra") | not)] as $others
  | all("dan-petty/infra", "github.com/dan-petty/infra", "https://github.com/dan-petty/infra",
      "https://github.com/dan-petty/infra.git";
      . as $name
      | any($topics[] as $i | $rules[$i]
        | select(.commitMessageTopic | startswith("dan-petty/infra"))
        | select(any(.matchPackageNames[]?; . as $p | startswith("/") and ($name | test($p[1:-1]))))
        | $i > ($others | max // -1); .))
' "$root/renovate/base.json" >/dev/null 2>&1; then
  echo "ok   renovate/base.json: each form of the infra name gets the topic dan-petty/infra"
else
  echo "FAIL renovate/base.json: a form of the infra name keeps its own name in the title"
  failures=$((failures + 1))
fi

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

# check NAME FILTER TEST [FILE]: exactly one dependency of FILE (default: the deps of the extract)
# matches the jq filter FILTER, and that dependency passes the jq test TEST.
check() {
  local name="$1" filter="$2" test="$3" file="${4:-$work/deps.jsonl}" deps
  cases=$((cases + 1))
  deps="$(jq -c "select($filter)" "$file")"
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

# The lookup. The JSON log at the level debug has one record with the message "packageFiles with
# updates": the result of the lookup of each dependency. A lookup that gets the repository of infra
# sets sourceUrl; a failed lookup sets a warning and no sourceUrl, also when infra has no release
# tag yet. The test turns off the OSV vulnerability alerts of base.json for the lookup: they
# download the OSV database, and the rules of the pins do not use it.
if [ -z "${RENOVATE_GITHUB_COM_TOKEN:-}" ]; then
  if [ "${CI:-}" = "true" ]; then
    cases=$((cases + 1))
    echo "FAIL renovate --platform=local --dry-run=lookup: CI sets no RENOVATE_GITHUB_COM_TOKEN"
    failures=$((failures + 1))
  else
    echo "skip renovate --platform=local --dry-run=lookup: set RENOVATE_GITHUB_COM_TOKEN to run it"
  fi
else
  jq '.osvVulnerabilityAlerts = false' "$work/repo/renovate.json" >"$work/lookup.json"
  mv "$work/lookup.json" "$work/repo/renovate.json"
  git -C "$work/repo" add --all
  cases=$((cases + 1))
  if (cd "$work/repo" && LOG_FORMAT=json LOG_LEVEL=debug renovate renovate --platform=local \
    --dry-run=lookup) >"$work/lookup.log" 2>&1; then
    echo "ok   renovate --platform=local --dry-run=lookup"
  else
    echo "FAIL renovate --platform=local --dry-run=lookup"
    tail -n 20 "$work/lookup.log" | sed 's/^/     /'
    failures=$((failures + 1))
  fi
  grep '^{' "$work/lookup.log" | jq -c '
    select(.msg == "packageFiles with updates") | .config | to_entries[] | .key as $manager
    | .value[] | .packageFile as $file | .deps[]
    | {manager: $manager, file: $file, depName, packageName, datasource, sourceUrl, warnings}' \
    >"$work/lookup.jsonl"
  for manager in kustomize terraform ansible-galaxy argocd github-actions; do
    check "$manager: the lookup of the pin of infra" ".manager == \"$manager\" and ($infra)" \
      '.sourceUrl == "https://github.com/dan-petty/infra" and (.warnings // []) == []' \
      "$work/lookup.jsonl"
  done
fi

echo "$((cases - failures)) of $cases cases passed"
[ "$failures" -eq 0 ]
