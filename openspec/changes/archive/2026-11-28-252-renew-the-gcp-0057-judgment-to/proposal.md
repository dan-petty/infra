# Proposal: renew the GCP-0057 judgment to 2026-12-01

## Why
`tf/.trivyignore.yaml` holds the judgment `GCP-0057` for `terraform-google-modules/kubernetes-engine/google/cluster.tf` (#252). Its `expired_at` date was `2026-11-28`, and its statement pointed to `#149`, which closed on `2026-11-25` in `v0.22.1`. From `2026-11-28`, the `trivy config` step of the `OpenTofu` CI job fails on `tf/examples/gcp` with `GCP-0057`.

## What Changes
- Renew `GCP-0057` in `tf/.trivyignore.yaml` to `expired_at: 2026-12-01` (3 more days, 9 days in all since `2026-11-22`, within the 14-day limit of `devops-cli` `SECURITY.md`).
- Update the comment and statement of `GCP-0057` in `tf/.trivyignore.yaml` to name the open tracking issue `dan-petty/infra#251`.
- This change updates only a CI ignore file (`tf/.trivyignore.yaml`) and alters no behavior that a consumer of `tf/modules/gcp-gke` observes, so it has no spec delta (`skip_specs: true`).

## Capabilities
None (CI ignore renewal only).

## Impact
Unblocks the `OpenTofu` CI job for pull requests and pushes until `2026-12-01`, while `dan-petty/infra#251` keeps tracking the removal of the entry. The change fits one pull request.

## Feasibility
Confirmed on `2026-11-28` against GitHub releases, the upstream module source, and `trivy config`:

- `aquasecurity/trivy` newest release is still `v0.76.2` (`2026-11-05`), pinned in `mise.toml`.
- `terraform-google-modules/kubernetes-engine/google` newest release is still `v47.0.0` (`2026-10-30`), pinned in `tf/modules/gcp-gke/main.tf`.
- In `v47.0.0` of that module, `var.identity_namespace` defaults to `"enabled"`, `var.node_metadata` defaults to `"GKE_METADATA"`, `tf/modules/gcp-gke/main.tf` sets `node_pools[0].node_metadata = "GKE_METADATA"`, and `cluster.tf` sets `workload_metadata_config.mode` inside a `dynamic "workload_metadata_config"` block of `node_config`.
- Running `trivy config --exit-code 1 --severity HIGH,CRITICAL --ignorefile tf/.trivyignore.yaml --skip-dirs '**/.terraform' --tf-vars tf/examples/gcp/gcp.tfvars.example tf/examples/gcp` on `2026-11-28` with `expired_at: 2026-11-28` exits 1 and reports only `GCP-0057`. With `expired_at: 2026-12-01`, all `tf/examples/*/` scans exit 0.

## Existing Tool Considered
`aquasecurity/trivy` (Apache-2.0, maintained), already used in CI with `tf/.trivyignore.yaml`. No new tool or code is built, and no internal code is deleted.
