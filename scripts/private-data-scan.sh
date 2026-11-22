#!/usr/bin/env bash
# The private-data guard of CI and of the pre-commit hook. It runs gitleaks with the rules of
# .gitleaks.toml. When the environment variable PRIVATE_DOMAINS holds domains, one on each line, the
# guard also runs the rule private-domain, which refuses each of these domains and each of their
# subdomains. In CI, PRIVATE_DOMAINS comes from the Actions secret of the same name. The domains go
# only into a temporary config file, never into the repository or the log. gitleaks redacts each
# finding in its output.
#
# Usage: scripts/private-data-scan.sh <gitleaks command> [<argument>...]
#   scripts/private-data-scan.sh dir .                       # scan the files of the tree
#   scripts/private-data-scan.sh git --pre-commit --staged   # scan the staged changes
# Exit codes: 0 no finding, 1 a finding (gitleaks), 2 PRIVATE_DOMAINS holds a line that is no
# domain name.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
config="$root/.gitleaks.toml"

# warn MESSAGE: an annotation and a line of the job summary in GitHub Actions, else a line on stderr.
warn() {
  if [ -n "${GITHUB_ACTIONS-}" ]; then
    echo "::warning title=Private-data guard::$1"
    if [ -n "${GITHUB_STEP_SUMMARY-}" ]; then
      printf '> [!WARNING]\n> %s\n' "$1" >>"$GITHUB_STEP_SUMMARY"
    fi
  else
    echo "warning: $1" >&2
  fi
}

domains=()
line_number=0
while IFS= read -r line || [ -n "$line" ]; do
  line_number=$((line_number + 1))
  line="$(printf '%s' "$line" | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')"
  [ -z "$line" ] && continue
  if ! [[ "$line" =~ ^[a-z0-9]([a-z0-9-]*[a-z0-9])?(\.[a-z0-9]([a-z0-9-]*[a-z0-9])?)+$ ]]; then
    # The message names the line only: the value can be a private domain.
    echo "Line $line_number of PRIVATE_DOMAINS is not a domain name." >&2
    exit 2
  fi
  domains+=("${line//./\\.}")
done <<<"${PRIVATE_DOMAINS-}"

if [ "${#domains[@]}" -gt 0 ]; then
  alternation="$(
    IFS='|'
    echo "${domains[*]}"
  )"
  work="$(mktemp -d)"
  trap 'rm -rf "$work"' EXIT
  # The rule takes the name in its group 1: the domain with each subdomain, between two characters
  # that cannot be part of a name.
  cat "$config" - >"$work/gitleaks.toml" <<EOF

[[rules]]
id = "private-domain"
description = "A domain of PRIVATE_DOMAINS, or a subdomain of one"
regex = '''(?i)(?:^|[^a-z0-9-])((?:[a-z0-9-]+\\.)*(?:${alternation}))(?:[^a-z0-9-]|\$)'''
secretGroup = 1
EOF
  config="$work/gitleaks.toml"
  echo "The rule private-domain refuses the ${#domains[@]} domains of PRIVATE_DOMAINS."
else
  warn "PRIVATE_DOMAINS is not set, so the rule private-domain did not run. The rules of .gitleaks.toml ran. In CI, a repository admin adds the Actions secret PRIVATE_DOMAINS, with one domain on each line."
fi

gitleaks "$@" --config "$config" --redact --verbose --no-banner
