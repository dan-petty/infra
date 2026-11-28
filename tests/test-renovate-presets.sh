#!/usr/bin/env bash
# Tests of the Renovate presets of renovate/ and of the Renovate config .github/renovate.json.
# - The config validator of Renovate checks each file in strict mode.
# - The fixture tests/renovate/ is a consumer repository: it holds one pin of infra in each consumer
#   form (README.md, "Pin a release"), a render of the repository template of
#   dan-petty/github-workflows with the caller of pr-title.yml that it renders, a caller of
#   k8s-validate.yml of dan-petty/github-workflows, a caller and a template render of infra from
#   before the move of #217, and a CloudNativePG Cluster. A consumer extends
#   github>dan-petty/infra//renovate/base and
#   github>dan-petty/infra//renovate/k8s. The local platform of Renovate does not resolve a preset of
#   a repository, so the test merges the two presets into one config, as Renovate merges the presets
#   of extends: the packageRules and the customManagers of k8s.json come after those of base.json,
#   and k8s.json sets each other key.
# - Renovate extracts the dependencies of a copy of the fixture with that config
#   (`--platform=local --dry-run=extract` reads the files of the working tree, looks up no release
#   and opens no pull request). The test checks that Renovate reads each pin of infra and of
#   dan-petty/github-workflows, at a release tag, with the datasource github-tags or git-tags, and
#   the image of the Cluster. The github-actions manager reads the caller of a reusable workflow as a
#   digest pin: the commit of the tag, with the tag in its comment, the form that the repository
#   template renders.
# - Renovate looks up the releases of each pin (`--dry-run=lookup`). The extract does not apply the
#   packageRules, so only the lookup proves a rule that changes the name that a lookup reads or that
#   turns a pin off. The test checks that each lookup gets the repository of the pin with no
#   warning, that Renovate leaves the caller that the template renders to the copier update, that
#   Renovate leaves each caller and each template render of infra alone, and that the copier update
#   gets at most one update. The datasource github-tags reads the GitHub API,
#   which needs a token: set RENOVATE_GITHUB_COM_TOKEN to a token that can read public repositories.
#   Without a token, the test skips the lookup; in CI (CI=true) the lookup is necessary.
# Run it with `mise exec -- tests/test-renovate-presets.sh`. npx installs the Renovate release of
# RENOVATE_VERSION with the Node of mise.toml, and runs no install script of a package.
set -euo pipefail

# renovate: datasource=npm depName=renovate
RENOVATE_VERSION=45.3.2

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

# Each manager names a repository in its own form, and the title takes that name. Each form of
# dan-petty/infra and of dan-petty/github-workflows gets a topic that starts with the short name of
# its repository, so that the title stays within the 60 characters of the title check. The last
# rule that sets a topic and can match the form gives the topic: a rule with no matchPackageNames
# can match each name.
# topic_case REPOSITORY: each form of the name of dan-petty/REPOSITORY gets a topic that starts with
# dan-petty/REPOSITORY.
topic_case() {
  cases=$((cases + 1))
  if jq -e --arg repo "dan-petty/$1" '
    .packageRules as $rules
    | [range(0; $rules | length) | select($rules[.].commitMessageTopic != null)] as $topics
    | all($repo, "github.com/\($repo)", "https://github.com/\($repo)", "https://github.com/\($repo).git";
        . as $name
        | [$topics[] as $i | $rules[$i]
          | select(.matchPackageNames == null or any(.matchPackageNames[];
              . as $p | if startswith("/") then ($name | test($p[1:-1])) else . == $name end))
          | $i] as $matches
        | ($matches | length) > 0
          and ($rules[$matches | max].commitMessageTopic | startswith($repo)))
  ' "$root/renovate/base.json" >/dev/null 2>&1; then
    echo "ok   renovate/base.json: each form of the name dan-petty/$1 gets the topic dan-petty/$1"
  else
    echo "FAIL renovate/base.json: a form of the name dan-petty/$1 keeps its own name in the title"
    failures=$((failures + 1))
  fi
}
topic_case infra
topic_case github-workflows

# The copier update of the repository template gets the topic dan-petty/github-workflows template,
# so that its title differs from the update of a caller of the same release.
cases=$((cases + 1))
if jq -e '
  .packageRules as $rules
  | [range(0; $rules | length) | select($rules[.].commitMessageTopic != null)
    | select(($rules[.].matchManagers // ["copier"]) | index("copier") != null)
    | select($rules[.].matchPackageNames == null or any($rules[.].matchPackageNames[];
        . as $p | startswith("/") and ("https://github.com/dan-petty/github-workflows.git" | test($p[1:-1]))))]
  | length > 0 and $rules[max].commitMessageTopic == "dan-petty/github-workflows template"
' "$root/renovate/base.json" >/dev/null 2>&1; then
  echo "ok   renovate/base.json: the copier update gets the topic dan-petty/github-workflows template"
else
  echo "FAIL renovate/base.json: the copier update has no topic of its own"
  failures=$((failures + 1))
fi

# The copier update runs `copier update` on a clean branch. In the group infra, the other managers
# change files of the branch first, and copier stops ("Destination repository is dirty", #216).
# So each rule of renovate/k8s.json that sets the group infra leaves the copier manager out.
cases=$((cases + 1))
if jq -e '
  [.packageRules[] | select(.groupName == "infra")] as $groups
  | ($groups | length) > 0 and all($groups[]; (.matchManagers // []) | index("!copier") != null)
' "$root/renovate/k8s.json" >/dev/null 2>&1; then
  echo "ok   renovate/k8s.json: the group infra leaves the copier update out"
else
  echo "FAIL renovate/k8s.json: the group infra takes the copier update"
  failures=$((failures + 1))
fi

# The repository template of dan-petty/github-workflows renders the callers
# .github/workflows/pr-title.yml and .github/workflows/release.yml (templates/repository/ of its
# tag v0.1.0), and the copier update moves their pin with the other files of the template (#225).
# So a rule of base.json turns off the github-actions manager for the pin of
# dan-petty/github-workflows in each of these files: each pin has one owner. Two owners make the
# copier update conflict.
callers='[".github/workflows/pr-title.yml", ".github/workflows/release.yml"]'
cases=$((cases + 1))
if jq -e --argjson callers "$callers" '
  any(.packageRules[]; .enabled == false
    and ((.matchManagers // []) | index("github-actions") != null)
    and ((.matchPackageNames // []) | index("dan-petty/github-workflows") != null)
    and ($callers - (.matchFileNames // []) == []))
' "$root/renovate/base.json" >/dev/null 2>&1; then
  echo "ok   renovate/base.json: Renovate leaves each caller of the template to the copier update"
else
  echo "FAIL renovate/base.json: Renovate moves a caller of the template: $callers"
  failures=$((failures + 1))
fi

# The workflows and the template left infra (#217): a newer release of infra has neither. So a rule
# of base.json turns off the github-actions manager and the copier manager for each form of the
# name of infra, in each file, with no other condition.
cases=$((cases + 1))
if jq -e '
  any(.packageRules[]; . as $rule | .enabled == false
    and ((.matchManagers // []) | sort) == ["copier", "github-actions"]
    and (keys - ["description", "enabled", "matchManagers", "matchPackageNames"] == [])
    and all("dan-petty/infra", "https://github.com/dan-petty/infra.git";
      . as $name | any($rule.matchPackageNames[]?; . as $p | startswith("/") and ($name | test($p[1:-1])))))
' "$root/renovate/base.json" >/dev/null 2>&1; then
  echo "ok   renovate/base.json: Renovate leaves each caller and each template render of infra alone"
else
  echo "FAIL renovate/base.json: Renovate moves a caller or a template render of infra"
  failures=$((failures + 1))
fi

# The copier update has one branch for each repository, with no split into major, minor and patch,
# so it always renders the newest release of the template (#225). Two copier branches change the
# same files and conflict.
cases=$((cases + 1))
if jq -e 'any(.packageRules[]; (.matchManagers // []) == ["copier"]
  and .separateMajorMinor == false and .separateMinorPatch == false)' \
  "$root/renovate/base.json" >/dev/null 2>&1; then
  echo "ok   renovate/base.json: the copier update has one branch"
else
  echo "FAIL renovate/base.json: the copier update has a branch for each update type"
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
# The consumer repository: a copy of the fixture, with the merged presets as its renovate.json. The
# local platform lists the files of the repository with git ls-files.
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
  | {manager: $manager, file: $file, depName, packageName, datasource, depType, currentValue,
     currentDigest, skipReason}' \
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
workflows='[.depName, .packageName] | any(. != null
  and test("github\\.com/dan-petty/github-workflows|^dan-petty/github-workflows$"))'
pin='(.datasource == "github-tags" or .datasource == "git-tags")
  and (.currentValue | test("^v[0-9]+\\.[0-9]+\\.[0-9]+$"))
  and (.skipReason == null or .skipReason == "github-token-required")'
expect() {
  check "$1: the pin of infra" ".manager == \"$1\" and ($infra)" "$pin"
}

# The fixture holds three callers of a reusable workflow: k8s.yml, a caller of the repository of
# dan-petty/github-workflows; pr-title.yml, a caller that the repository template renders; and
# k8s-infra.yml, a caller of infra from before #217. It holds two template renders:
# .copier-answers.yml of dan-petty/github-workflows and .copier-answers.infra.yml of infra.
k8s_caller='.manager == "github-actions" and .file == ".github/workflows/k8s.yml"'
template_caller='.manager == "github-actions" and .file == ".github/workflows/pr-title.yml"'
infra_caller='.manager == "github-actions" and .file == ".github/workflows/k8s-infra.yml"'
template_render='.manager == "copier" and .file == ".copier-answers.yml"'
infra_render='.manager == "copier" and .file == ".copier-answers.infra.yml"'

expect kustomize
expect terraform
expect ansible-galaxy
expect argocd
check "copier: the pin of infra" "$infra_render and ($infra)" "$pin"
check "copier: the pin of dan-petty/github-workflows" "$template_render and ($workflows)" "$pin"
check "github-actions: the pin of infra" "$infra_caller and ($infra)" "$pin"
check "github-actions: the pin of dan-petty/github-workflows" "$k8s_caller and ($workflows)" "$pin"

# The github-actions manager reads a caller of a reusable workflow as a digest pin: the commit of the
# tag v0.1.0, with the tag in its comment, the text that the repository template renders.
for workflow in k8s pr-title; do
  check "github-actions: the digest pin of the reusable workflow in $workflow.yml" \
    ".manager == \"github-actions\" and .file == \".github/workflows/$workflow.yml\" and ($workflows)" \
    '.depType == "workflow" and .currentValue == "v0.1.0"
    and .currentDigest == "39f92fb644e550f84a5797cce46a80a891231d4a"'
done
check "github-actions: the digest pin of the reusable workflow of infra in k8s-infra.yml" \
  "$infra_caller and ($infra)" '.depType == "workflow" and .currentValue == "v0.1.0"
    and .currentDigest == "aacb6e4661513b20885ebd56f1f2edb89534d5cd"'

# The CloudNativePG custom manager reads the image of spec.imageName of the Cluster, and not the
# deeper imageName field of the Helm values.
check "custom.regex: the image of the CloudNativePG Cluster" '.manager == "regex"' \
  '.file == "k8s/cluster.yaml" and .datasource == "docker"
  and .depName == "ghcr.io/cloudnative-pg/postgresql" and .currentValue == "17.5"'

# The lookup. The JSON log at the level debug has one record with the message "packageFiles with
# updates": the result of the lookup of each dependency. A lookup that gets the repository of a pin
# sets sourceUrl; a failed lookup sets a warning and no sourceUrl, also when the repository has no
# release tag yet. The test turns off the OSV vulnerability alerts of base.json for the lookup: they
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
    | {manager: $manager, file: $file, depName, packageName, datasource, sourceUrl, warnings,
       skipReason, updates: [.updates[]? | {updateType, newValue, bucket, branchName}]}' \
    >"$work/lookup.jsonl"
  for filter in '.manager == "kustomize"' '.manager == "terraform"' '.manager == "ansible-galaxy"' \
    '.manager == "argocd"'; do
    check "$filter: the lookup of the pin of infra" "$filter and ($infra)" \
      '.sourceUrl == "https://github.com/dan-petty/infra" and (.warnings // []) == []' \
      "$work/lookup.jsonl"
  done
  for filter in "$template_render" "$k8s_caller"; do
    check "$filter: the lookup of the pin of dan-petty/github-workflows" "$filter and ($workflows)" \
      '.sourceUrl == "https://github.com/dan-petty/github-workflows" and (.warnings // []) == []' \
      "$work/lookup.jsonl"
  done
  # Renovate leaves the pin of the caller that the template renders to the copier update, and each
  # caller and each template render of infra alone.
  check "github-actions: Renovate leaves the caller of the template to the copier update" \
    "$template_caller and ($workflows)" '.skipReason == "disabled"' "$work/lookup.jsonl"
  check "github-actions: Renovate leaves the caller of infra alone" \
    "$infra_caller and ($infra)" '.skipReason == "disabled"' "$work/lookup.jsonl"
  check "copier: Renovate leaves the template render of infra alone" \
    "$infra_render and ($infra)" '.skipReason == "disabled"' "$work/lookup.jsonl"
  # The copier update gets at most one update, to the newest release, also when the rendered tag has
  # a newer patch and a newer minor release, and on a branch of its own, not in a group (#216).
  check "copier: at most one update, on a branch of its own" "$template_render" \
    '(.updates | length) <= 1
    and all(.updates[]; .branchName | startswith("renovate/https-github.com-dan-petty-github-workflows"))' \
    "$work/lookup.jsonl"
fi

echo "$((cases - failures)) of $cases cases passed"
[ "$failures" -eq 0 ]
