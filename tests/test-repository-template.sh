#!/usr/bin/env bash
# Tests of the Copier template of a new repository: copier.yml and templates/repository/
# (README.md, "Repository template"). The test renders the template with each answer set into a
# temporary folder, with `copier copy --defaults --vcs-ref HEAD` and no --trust, as
# `devops repos onboard` renders a release tag. --vcs-ref HEAD renders the working tree, also the
# changes that are not committed. Then it checks the rendered files:
#   - the set of files: the release files only when the release flow is on, version.txt only for
#     the release type simple, and no file with the suffix .jinja,
#   - actionlint on the workflows, yamllint --strict on each YAML file, tomllib on
#     .devops/project.toml, pre-commit validate-config, and the schema spec-driven of
#     openspec/config.yaml,
#   - check-jsonschema: github/repository.yaml with templates/github-repository.schema.json, and the
#     release-please files with the schemas of the release-please release of RELEASE_PLEASE_VERSION,
#   - the config validator of Renovate, in strict mode, on .github/renovate.json,
#   - the answers in the files: the scope labels, the release type, the environment release, the
#     tag of infra in the callers of the reusable workflows (infra_ref, else _commit), the secret
#     that the release caller passes by name, and the code owner,
#   - that infra holds each workflow that a caller calls as a reusable workflow, with each secret
#     that the release caller passes,
#   - that Copier refuses a scope that is not a lowercase name.
# Run it from the repository root after `uv sync --frozen`: `mise exec -- tests/test-repository-template.sh`.
# npx installs the Renovate release of RENOVATE_VERSION with the Node of mise.toml, and runs no
# install script of a package. check-jsonschema downloads the release-please schemas from GitHub.
set -euo pipefail

# renovate: datasource=npm depName=renovate
RENOVATE_VERSION=44.261.3
# renovate: datasource=npm depName=release-please
RELEASE_PLEASE_VERSION=17.11.2

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
failures=0
cases=0
export PATH="$root/.venv/bin:$PATH"
export npm_config_ignore_scripts=true npm_config_update_notifier=false npm_config_audit=false \
  npm_config_fund=false RENOVATE_BASE_DIR="$work/renovate"
schemas="https://raw.githubusercontent.com/googleapis/release-please/v$RELEASE_PLEASE_VERSION/schemas"
# The tag of infra that the callers of the reusable workflows pin. A render of a release tag gets
# that tag; a render of HEAD gets the output of git describe, so the test gives a tag.
ref=v1.2.3

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

# expect NAME WANT GOT: WANT and GOT are the same text.
expect() {
  cases=$((cases + 1))
  if [ "$2" = "$3" ]; then
    echo "ok   $1"
  else
    echo "FAIL $1"
    echo "     want: $2"
    echo "     got:  $3"
    failures=$((failures + 1))
  fi
}

# render NAME DATA...: render the template into $work/NAME with the answers DATA (key=value).
render() {
  local name="$1" args=()
  shift
  for data in "$@"; do
    args+=(--data "$data")
  done
  check "$name: copier copy" copier copy --quiet --defaults --vcs-ref HEAD \
    --data "infra_ref=$ref" "${args[@]}" "$root" "$work/$name"
}

# files DIR: the files of DIR, one on each line, in sort order.
files() {
  (cd "$1" && find . -type f -printf '%P\n' | LC_ALL=C sort)
}

# validate NAME: the validators of each rendered file of $work/NAME.
validate() {
  local dir="$work/$1" yaml=()
  mapfile -t yaml < <(find "$dir" -type f \( -name '*.yaml' -o -name '*.yml' \) | LC_ALL=C sort)
  check "$1: actionlint" actionlint "$dir"/.github/workflows/*.yml
  check "$1: yamllint --strict" yamllint --strict -c "$root/.yamllint.yaml" "${yaml[@]}"
  check "$1: pre-commit validate-config" pre-commit validate-config "$dir/.pre-commit-config.yaml"
  check "$1: .devops/project.toml is TOML" python -c \
    'import sys, tomllib; tomllib.load(open(sys.argv[1], "rb"))' "$dir/.devops/project.toml"
  expect "$1: the OpenSpec schema" "spec-driven" "$(yq -r '.schema' "$dir/openspec/config.yaml")"
  check "$1: github/repository.yaml matches its schema" check-jsonschema \
    --schemafile "$root/templates/github-repository.schema.json" "$dir/github/repository.yaml"
  if [ -f "$dir/release-please-config.json" ]; then
    check "$1: release-please-config.json matches its schema" check-jsonschema \
      --schemafile "$schemas/config.json" "$dir/release-please-config.json"
    check "$1: .release-please-manifest.json matches its schema" check-jsonschema \
      --schemafile "$schemas/manifest.json" "$dir/.release-please-manifest.json"
  fi
}

# labels NAME: the names of the labels of $work/NAME, on one line.
labels() {
  yq -r '[.[].name] | join(" ")' "$work/$1/.github/labels.yml"
}

# uses NAME WORKFLOW: the `uses` of each job of the workflow WORKFLOW of $work/NAME, on one line.
uses() {
  yq -r '[.jobs[].uses] | join(" ")' "$work/$1/.github/workflows/$2"
}

check "the schema of github/repository.yaml is a valid JSON Schema" check-jsonschema \
  --check-metaschema "$root/templates/github-repository.schema.json"

common='.copier-answers.yml
.devops/project.toml
.github/CODEOWNERS
.github/labels.yml
.github/renovate.json
.github/workflows/pr-title.yml
.pre-commit-config.yaml
github/repository.yaml
openspec/config.yaml'
release='.github/workflows/release.yml
.release-please-manifest.json
release-please-config.json'

# The default answers: no release flow (decision D2 of devops-cli#6773: a private repository on the
# Free plan) and no scope of its own. The repository gets no release workflow, no release-please
# file and no environment release.
render defaults
validate defaults
expect "defaults: files" "$(printf '%s\n' "$common" | LC_ALL=C sort)" "$(files "$work/defaults")"
expect "defaults: labels" "scope/ci scope/deps scope/docs" "$(labels defaults)"
expect "defaults: no environment" "0" \
  "$(yq -r '.environments // [] | length' "$work/defaults/github/repository.yaml")"
expect "defaults: the pin of the reusable PR title workflow" \
  "dan-petty/infra/.github/workflows/pr-title.yml@$ref" "$(uses defaults pr-title.yml)"
expect "defaults: code owner" "* @dan-petty" "$(grep -v '^#' "$work/defaults/.github/CODEOWNERS")"
check "defaults: renovate-config-validator --strict" npx --yes --package "renovate@$RENOVATE_VERSION" \
  -- renovate-config-validator --strict "$work/defaults/.github/renovate.json"
expect "defaults: infra_ref is not in .copier-answers.yml" "null" \
  "$(yq -r '.infra_ref' "$work/defaults/.copier-answers.yml")"
expect "defaults: code_coverage is false in .copier-answers.yml" "false" \
  "$(yq -r '.code_coverage' "$work/defaults/.copier-answers.yml")"
expect "defaults: no code_coverage rule" "0" \
  "$(yq -r '[.rulesets[0].rules[] | select(.type == "code_coverage")] | length' "$work/defaults/github/repository.yaml")"

# With code_coverage=true, the rendered ruleset holds the code_coverage rule with minimum_coverage: 80.
render coverage code_coverage=true
validate coverage
expect "coverage: code_coverage is true in .copier-answers.yml" "true" \
  "$(yq -r '.code_coverage' "$work/coverage/.copier-answers.yml")"
expect "coverage: minimum_coverage is 80" "80" \
  "$(yq -r '.rulesets[0].rules[] | select(.type == "code_coverage") | .parameters.minimum_coverage' "$work/coverage/github/repository.yaml")"

# With no answer infra_ref, the callers pin _commit, the version of infra that Copier renders.
check "commit: copier copy" copier copy --quiet --defaults --vcs-ref HEAD "$root" "$work/commit"
expect "commit: the pin of the reusable PR title workflow" \
  "dan-petty/infra/.github/workflows/pr-title.yml@$(yq -r '._commit' "$work/commit/.copier-answers.yml")" \
  "$(uses commit pr-title.yml)"

# The release flow with each release type, and two scopes of the repository. A scope of the
# template, here docs, comes once.
for type in simple python node; do
  render "$type" release_flow=true "release_type=$type" "scopes=api, worker,docs"
  validate "$type"
  want="$(printf '%s\n%s' "$common" "$release")"
  if [ "$type" = simple ]; then
    want="$(printf '%s\nversion.txt' "$want")"
  fi
  expect "$type: files" "$(printf '%s\n' "$want" | LC_ALL=C sort)" "$(files "$work/$type")"
  expect "$type: labels" \
    "scope/ci scope/deps scope/docs scope/api scope/worker autorelease: pending autorelease: tagged" \
    "$(labels "$type")"
  expect "$type: release type" "$type" \
    "$(jq -r '."release-type"' "$work/$type/release-please-config.json")"
done

# The release caller pins the tag of infra, gives the job token no permission, and passes the
# secret of the release App by name, never with `secrets: inherit`. The job of the reusable workflow
# gets the value of the secret of the environment release.
expect "simple: the environment release" "release" \
  "$(yq -r '[.environments[].name] | join(" ")' "$work/simple/github/repository.yaml")"
expect "simple: the pin of the reusable release workflow" \
  "dan-petty/infra/.github/workflows/release.yml@$ref" "$(uses simple release.yml)"
expect "simple: the permissions of the release caller" "{}" \
  "$(yq -o=json -I=0 '.jobs.release.permissions' "$work/simple/.github/workflows/release.yml")"
# shellcheck disable=SC2016 # The expression of GitHub Actions, not of the shell.
expect "simple: the secrets of the release caller" \
  'RELEASE_APP_PRIVATE_KEY=${{ secrets.RELEASE_APP_PRIVATE_KEY }}' \
  "$(yq -r '.jobs.release.secrets | select(tag == "!!map") | to_entries |
    map(.key + "=" + .value) | join(" ")' "$work/simple/.github/workflows/release.yml")"

# A repository that infra renders at a release tag calls the workflows of infra at that tag, so the
# same commit of infra holds each workflow that a caller calls, as a reusable workflow
# (on: workflow_call). The release caller passes each secret that the reusable release workflow
# declares.
while read -r called; do
  path="${called#dan-petty/infra/}"
  path="${path%@*}"
  check "infra holds the reusable workflow $path" yq -e '.on | has("workflow_call")' "$root/$path"
done < <(yq --no-doc -r '.jobs[].uses' "$work/simple"/.github/workflows/*.yml | LC_ALL=C sort -u)
expect "the release caller passes each secret of the reusable release workflow" \
  "$(yq -r '(.on.workflow_call.secrets // {}) | keys | join(" ")' \
    "$root/.github/workflows/release.yml")" \
  "$(yq -r '.jobs.release.secrets | select(tag == "!!map") | keys | join(" ")' \
    "$work/simple/.github/workflows/release.yml")"
check "release workflow enables auto-merge on the release pull request" \
  yq -e '.jobs.release-please.steps[] | select(.name == "Enable auto-merge on the release pull request")' \
  "$root/.github/workflows/release.yml"

# Copier refuses a scope that is not a lowercase name, and the scope main of the release pull request.
for scopes in "Bad Scope" "api,main"; do
  cases=$((cases + 1))
  if copier copy --quiet --defaults --vcs-ref HEAD --data "infra_ref=$ref" --data "scopes=$scopes" \
    "$root" "$work/refused" >"$work/refused.log" 2>&1; then
    echo "FAIL copier refuses scopes=$scopes"
    failures=$((failures + 1))
  else
    echo "ok   copier refuses scopes=$scopes"
  fi
  rm -rf "$work/refused"
done

echo "$((cases - failures)) of $cases cases passed"
[ "$failures" -eq 0 ]
