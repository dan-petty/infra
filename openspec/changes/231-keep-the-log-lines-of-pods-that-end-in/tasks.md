# Tasks

## 1. Pod logs

Kind: behavior. Changes: `helm/k8s-monitoring/values.yaml`, `helm/k8s-monitoring/test-chart/tests/pod_logs_test.yaml`, `helm/README.md`.

- [x] 1.1 Write the tests of the rendered `tail_from_end` and of the host path of the read positions
  - Verification: `KUSTOMIZE_ROOTS= HELM_CHARTS=helm/k8s-monitoring/test-chart PROMTOOL_RULES= TRIVY_IGNORE_FILE=helm/.trivyignore.yaml mise exec -- scripts/k8s-validate.sh helm-unittest` failed the first test on `main`
- [x] 1.2 Set `podLogsViaLoki.onlyGatherNewLogLines: false`, and name it in `helm/README.md`
  - Verification: the same command passes both tests

## Workflow follow-up

- Pending a person: the change reaches dan-petty/homelab through an infra release and the Renovate update of its infra tag. After the sync, a Job pod that lives about 5 s has its lines in Loki (dan-petty/homelab#583).
