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
#   - the answers in the files: the scope labels and their descriptions, the release type, the
#     environment release, the secret that the release caller passes by name, the code owner, and
#     the required checks: the title check of the template and each check of the answer
#     required_checks,
#   - the pin of each caller of a reusable workflow of infra: the commit that Copier renders, with
#     the tag of infra (infra_ref, else _commit) in a comment, and no bare tag,
#   - a render of a lightweight release tag: each caller pins the commit of the tag. Then the
#     repository writes its own content into each file of _skip_if_exists, and the next tag changes
#     each file of the template. `copier update` (as Renovate runs it) and `copier recopy
#     --overwrite` (the re-adoption of a repository with changed template files) give no conflict,
#     keep each file of _skip_if_exists, and give each other file the render of the next tag,
#   - that a render of a template folder with no git fails with a message, and writes no `@None`,
#   - that infra holds each workflow that a caller calls as a reusable workflow, with each secret
#     that the release caller passes,
#   - that Copier refuses a scope that is not a lowercase name, a check name that is not plain, and a
#     scope description of an unknown scope, or that is not a plain text of 1 to 100 characters.
# Run it from the repository root after `uv sync --frozen`: `mise exec -- tests/test-repository-template.sh`.
# npx installs the Renovate release of RENOVATE_VERSION with the Node of mise.toml, and runs no
# install script of a package. check-jsonschema downloads the release-please schemas from GitHub.
set -euo pipefail

# renovate: datasource=npm depName=renovate
RENOVATE_VERSION=45.1.0
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
# The tag of infra in the comment of the callers of the reusable workflows. A render of a release
# tag gets that tag; a render of HEAD gets the output of git describe, so the test gives a tag.
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

# pins DIR: each `uses:` line of a caller of infra in the workflows of DIR, with no indent, one on
# each line, in sort order.
pins() {
  grep -h -E '^[[:space:]]*uses:.*dan-petty/infra/' "$1"/.github/workflows/*.yml |
    sed -E 's/^[[:space:]]+//' | LC_ALL=C sort
}

# pinned DIR TAG: each caller of infra in the workflows of DIR pins a commit SHA of 40 characters,
# with the comment `# TAG`, as the github-actions manager of Renovate writes a digest pin. It prints
# each other caller, such as a bare tag, and fails also when DIR holds no caller of infra.
pinned() {
  local lines
  lines="$(pins "$1")"
  if [ -z "$lines" ]; then
    echo "no caller of infra"
    return 1
  fi
  ! printf '%s\n' "$lines" |
    grep -v -E "^uses: dan-petty/infra/\.github/workflows/[a-z0-9-]+\.yml@[0-9a-f]{40} # ${2//./\\.}\$"
}

# validate NAME [TAG]: the validators of each rendered file of $work/NAME. TAG is the tag of infra in
# the callers, by default $ref.
validate() {
  local dir="$work/$1" yaml=()
  mapfile -t yaml < <(find "$dir" -type f \( -name '*.yaml' -o -name '*.yml' \) | LC_ALL=C sort)
  check "$1: each caller of infra pins a commit SHA with the comment # ${2:-$ref}" \
    pinned "$dir" "${2:-$ref}"
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

# required NAME: the required checks of the ruleset main of $work/NAME, separated by commas.
required() {
  yq -r '[.rulesets[0].rules[] | select(.type == "required_status_checks")
    | .parameters.required_status_checks[].context] | join(",")' "$work/$1/github/repository.yaml"
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
expect "defaults: the reusable PR title workflow" \
  "dan-petty/infra/.github/workflows/pr-title.yml" "$(uses defaults pr-title.yml | sed 's/@.*//')"
expect "defaults: code owner" "* @dan-petty" "$(grep -v '^#' "$work/defaults/.github/CODEOWNERS")"
check "defaults: renovate-config-validator --strict" npx --yes --package "renovate@$RENOVATE_VERSION" \
  -- renovate-config-validator --strict "$work/defaults/.github/renovate.json"
expect "defaults: infra_ref is not in .copier-answers.yml" "null" \
  "$(yq -r '.infra_ref' "$work/defaults/.copier-answers.yml")"
expect "defaults: code_coverage is false in .copier-answers.yml" "false" \
  "$(yq -r '.code_coverage' "$work/defaults/.copier-answers.yml")"
expect "defaults: no code_coverage rule" "0" \
  "$(yq -r '[.rulesets[0].rules[] | select(.type == "code_coverage")] | length' "$work/defaults/github/repository.yaml")"

# The ruleset main requires the check of the title caller, which GitHub names "<job of the caller> /
# <job of the reusable workflow>", and each check of the answer required_checks, once. Integration
# 15368 is GitHub Actions: only a job of a workflow can report a required check.
title_check="$(yq -r '.jobs[].name' "$work/defaults/.github/workflows/pr-title.yml") / $(
  yq -r '.jobs[].name' "$root/.github/workflows/pr-title.yml")"
expect "defaults: the required checks" "$title_check" "$(required defaults)"
render checks "required_checks=K8s, Lint / yamllint,K8s"
validate checks
expect "checks: the required checks" "K8s,Lint / yamllint,$title_check" "$(required checks)"
expect "checks: each required check comes from GitHub Actions" "15368" \
  "$(yq -r '[.rulesets[0].rules[] | select(.type == "required_status_checks")
    | .parameters.required_status_checks[].integration_id] | unique | join(",")' \
    "$work/checks/github/repository.yaml")"

# With code_coverage=true, the rendered ruleset holds the code_coverage rule with minimum_coverage: 80.
render coverage code_coverage=true
validate coverage
expect "coverage: code_coverage is true in .copier-answers.yml" "true" \
  "$(yq -r '.code_coverage' "$work/coverage/.copier-answers.yml")"
expect "coverage: minimum_coverage is 80" "80" \
  "$(yq -r '.rulesets[0].rules[] | select(.type == "code_coverage") | .parameters.minimum_coverage' "$work/coverage/github/repository.yaml")"

# A render of a release tag, as `devops repos onboard` renders it, with no answer infra_ref. The
# source is a git repository with copier.yml and templates/ of the working tree, and lightweight
# tags, as the release tags of infra. Each caller pins the commit of the tag, with the tag in a
# comment: the text that the github-actions manager of Renovate writes for a digest pin of the tag.
gitq() {
  git -c user.name=test -c user.email=test@example.com -c commit.gpgsign=false \
    -c tag.gpgsign=false -c core.hooksPath=/dev/null -c init.defaultBranch=main "$@"
}
src="$work/src"
mkdir "$src"
cp -R "$root/copier.yml" "$root/templates" "$src/"
gitq -C "$src" init --quiet
gitq -C "$src" add --all
gitq -C "$src" commit --quiet -m "the template"
gitq -C "$src" tag v1.0.0
first="$(git -C "$src" rev-parse 'v1.0.0^{commit}')"
check "tag: copier copy" copier copy --quiet --defaults --vcs-ref v1.0.0 --data release_flow=true \
  "$src" "$work/tag"
validate tag v1.0.0
expect "tag: _commit" "v1.0.0" "$(yq -r '._commit' "$work/tag/.copier-answers.yml")"
expect "tag: each caller pins the commit of the tag" \
  "uses: dan-petty/infra/.github/workflows/pr-title.yml@$first # v1.0.0
uses: dan-petty/infra/.github/workflows/release.yml@$first # v1.0.0" "$(pins "$work/tag")"

# Each file has one owner. The files of $kept belong to the repository after the first copy
# (_skip_if_exists of copier.yml): the repository writes its own rules into them, and release-please
# writes the version files. The template owns each other file, also the callers of infra: Renovate
# leaves their pins to the copier update. Here the repository of v1.0.0 writes its own content into
# each file of $kept, and the release v1.1.0 changes each file of the template.
kept='.devops/project.toml
.github/renovate.json
.pre-commit-config.yaml
.release-please-manifest.json
version.txt'
gitq -C "$work/tag" init --quiet
gitq -C "$work/tag" add --all
gitq -C "$work/tag" commit --quiet -m "the render of v1.0.0"
printf '[kubernetes]\ndir = "k8s"\n' >>"$work/tag/.devops/project.toml"
jq '.packageRules = [{"matchPackageNames": ["example"], "enabled": false}]' \
  "$work/tag/.github/renovate.json" >"$work/renovate.json"
mv "$work/renovate.json" "$work/tag/.github/renovate.json"
printf '  - repo: local\n    hooks: []\n' >>"$work/tag/.pre-commit-config.yaml"
printf '{\n  ".": "1.4.0"\n}\n' >"$work/tag/.release-please-manifest.json"
printf '1.4.0\n' >"$work/tag/version.txt"
gitq -C "$work/tag" commit --quiet --all -m "the content of the repository"
while read -r file; do
  case "$file" in
    *answers_file*) ;;
    *.json | *.json.jinja) sed -i '1a\  "x-release": "v1.1.0",' "$src/templates/repository/$file" ;;
    *) sed -i '1i # The release v1.1.0.' "$src/templates/repository/$file" ;;
  esac
done < <(files "$src/templates/repository")
gitq -C "$src" commit --quiet --all -m "the next release"
gitq -C "$src" tag v1.1.0
next="$(git -C "$src" rev-parse 'v1.1.0^{commit}')"
check "next: copier copy" copier copy --quiet --defaults --vcs-ref v1.1.0 --data release_flow=true \
  "$src" "$work/next"

cp -R "$work/tag" "$work/update"
cp -R "$work/tag" "$work/recopy"

# A repository that re-adopts the template once: Renovate moved its callers to another release, and
# a person changed files of the template. `copier recopy --overwrite` renders v1.1.0 over it.
sed -i -E 's/@[0-9a-f]{40} # v1\.0\.0$/@0000000000000000000000000000000000000000 # v1.0.1/' \
  "$work/recopy"/.github/workflows/*.yml
printf '# An old comment.\n' >>"$work/recopy/.github/CODEOWNERS"
printf -- '- name: "type/bug"\n  color: "D73A4A"\n' >>"$work/recopy/.github/labels.yml"
gitq -C "$work/recopy" commit --quiet --all -m "the changes of a person and of Renovate"

# conflicts DIR: each conflict marker and each rejected hunk (.rej) of DIR.
conflicts() {
  grep -rl --exclude-dir=.git -E '^(<<<<<<<|>>>>>>>)( |$)' "$1" || true
  find "$1" -name '*.rej'
}

# owned DIR: each file of the template in DIR, outside $kept, that differs from $work/next.
owned() {
  local skip=()
  while read -r file; do
    skip+=(-x "$(basename "$file")")
  done <<<"$kept"
  diff -rq -x .git "${skip[@]}" "$work/next" "$1" || true
}

# The copier manager of Renovate runs `copier update --skip-answered --defaults`.
check "update: copier update" copier update --quiet --skip-answered --defaults --vcs-ref v1.1.0 \
  "$work/update"
check "recopy: copier recopy" copier recopy --quiet --skip-answered --defaults --overwrite \
  --vcs-ref v1.1.0 "$work/recopy"
for name in update recopy; do
  dir="$work/$name"
  expect "$name: no conflict" "" "$(conflicts "$dir")"
  # shellcheck disable=SC2086 # Each line of $kept is one path.
  expect "$name: each file of the repository keeps its content" "" \
    "$(git -C "$dir" status --porcelain --untracked-files=all -- $kept)"
  expect "$name: each file of the template is the render of v1.1.0" "" "$(owned "$dir")"
  expect "$name: _commit" "v1.1.0" "$(yq -r '._commit' "$dir/.copier-answers.yml")"
  expect "$name: each caller pins the commit of the next tag" \
    "uses: dan-petty/infra/.github/workflows/pr-title.yml@$next # v1.1.0
uses: dan-petty/infra/.github/workflows/release.yml@$next # v1.1.0" "$(pins "$dir")"
done

# A template folder that is not a git repository gives Copier no commit (_copier_conf.vcs_ref_hash
# is None). The render fails with a message, and writes no caller with `@None`.
mkdir "$work/plain"
cp -R "$root/copier.yml" "$root/templates" "$work/plain/"
cases=$((cases + 1))
if copier copy --quiet --defaults "$work/plain" "$work/plain-render" >"$work/plain.log" 2>&1; then
  echo "FAIL copier refuses a template with no commit"
  pins "$work/plain-render" | sed 's/^/     /'
  failures=$((failures + 1))
elif ! grep -q 'Copier gives no commit of the template' "$work/plain.log"; then
  echo "FAIL copier refuses a template with no commit: the message is missing"
  tail -n 3 "$work/plain.log" | sed 's/^/     /'
  failures=$((failures + 1))
else
  echo "ok   copier refuses a template with no commit"
fi

# The answer scope_descriptions gives a scope label its own description, also a scope of the
# template. Each other scope label gets the description of the template.
render described "scopes=api,worker" \
  'scope_descriptions={api: "The HTTP API in api/", ci: "Workflows: build, scan and publish"}'
validate described
expect "described: the descriptions of the scope labels" \
  "Workflows: build, scan and publish|Dependency pins and the updates of Renovate|README and other documents|The HTTP API in api/|The area worker of this repository" \
  "$(yq -r '[.[] | select(.name | test("^scope/")) | .description] | join("|")' \
    "$work/described/.github/labels.yml")"

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

# The release caller calls the reusable release workflow of infra, gives the job token no
# permission, and passes the secret of the release App by name, never with `secrets: inherit`. The
# job of the reusable workflow gets the value of the secret of the environment release.
expect "simple: the environment release" "release" \
  "$(yq -r '[.environments[].name] | join(" ")' "$work/simple/github/repository.yaml")"
expect "simple: the reusable release workflow" \
  "dan-petty/infra/.github/workflows/release.yml" "$(uses simple release.yml | sed 's/@.*//')"
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
check "release workflow requests review on the release pull request" \
  yq -e '.jobs.release-please.steps[] | select(.name == "Request review on the release pull request")' \
  "$root/.github/workflows/release.yml"

# Copier refuses a scope that is not a lowercase name, the scope main of the release pull request,
# a check name that is not a plain YAML text, a description of a scope that the repository does not
# have, and a description that is not a text of 1 to 100 characters with no quote or backslash.
for data in "scopes=Bad Scope" "scopes=api,main" "required_checks=K8s: lint" \
  "scope_descriptions={api: The API}" 'scope_descriptions={docs: "The \"docs\""}' \
  "scope_descriptions={docs: ''}" "scope_descriptions=[docs]"; do
  cases=$((cases + 1))
  if copier copy --quiet --defaults --vcs-ref HEAD --data "infra_ref=$ref" --data "$data" \
    "$root" "$work/refused" >"$work/refused.log" 2>&1; then
    echo "FAIL copier refuses $data"
    failures=$((failures + 1))
  else
    echo "ok   copier refuses $data"
  fi
  rm -rf "$work/refused"
done

echo "$((cases - failures)) of $cases cases passed"
[ "$failures" -eq 0 ]
