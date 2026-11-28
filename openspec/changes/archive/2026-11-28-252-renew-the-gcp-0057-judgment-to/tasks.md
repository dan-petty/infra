# Tasks

## 1. Data

- [x] 1.1 Renew the `GCP-0057` entry in `tf/.trivyignore.yaml` to `expired_at: 2026-12-01` and reference `dan-petty/infra#251`
  - Verification: `$ mise exec -- trivy config --exit-code 1 --severity HIGH,CRITICAL --ignorefile tf/.trivyignore.yaml --skip-dirs '**/.terraform' --tf-vars tf/examples/gcp/gcp.tfvars.example tf/examples/gcp`
- [x] 1.2 Run the `OpenTofu`, `YAML`, and `Private-data guard` checks locally
  - Verification: `$ mise exec -- tests/test-trivyignore.sh && mise exec -- tests/test-private-data-scan.sh && mise exec -- scripts/private-data-scan.sh dir .`
