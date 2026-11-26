# Design

## Decisions
- A job of its own reports the one name. `always()` and not `!cancelled()`, because GitHub counts a skipped required check as passed.
- The test reads `ci.yml` with `yq` and runs the script of the reporting job with each result.

## Rejected alternatives
- Require `K8s / Validate` in the ruleset: a pull request with no Kubernetes change never gets that name.
- Remove `K8s` from the ruleset: a failed validation could then merge.
