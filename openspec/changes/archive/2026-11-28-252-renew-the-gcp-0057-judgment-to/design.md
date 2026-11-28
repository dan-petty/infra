# Design

## Decisions
- Renew `GCP-0057` in `tf/.trivyignore.yaml` for 3 days (`2026-12-01`), bringing total ignore duration from `2026-11-22` to 9 days (within the 14-day maximum in `devops-cli` `SECURITY.md`).
- Reference `dan-petty/infra#251` as the open tracking issue in `tf/.trivyignore.yaml`, while `#252` tracks this renewal pull request so `release-please` does not close `#251` on release.

## Rejected alternatives
- **Remove the `GCP-0057` entry or bump `trivy` / GKE module**: Rejected because `trivy` `v0.76.2` and `terraform-google-modules/kubernetes-engine/google` `v47.0.0` are already the newest releases on `2026-11-28`, and `trivy config` still reports `GCP-0057` when `expired_at` is `2026-11-28`.
- **Replace the maintained GKE module with raw `google_container_*` resources**: Rejected because `tf/modules/gcp-gke` is a thin wrapper over the maintained registry modules by design (`tf/modules/gcp-gke/README.md`).
