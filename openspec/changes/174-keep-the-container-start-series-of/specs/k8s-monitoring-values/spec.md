## Purpose
The values template helm/k8s-monitoring/values.yaml of the Grafana k8s-monitoring chart keeps the kube-state-metrics series that measure the containers of a pod, such as the container start time that a runner Job needs.

## ADDED Requirements

### Requirement: The kube-state-metrics allowlist keeps the container start series
The kube-state-metrics `includeMetrics` list of `helm/k8s-monitoring/values.yaml` SHALL hold `kube_pod_container_state_started`, so the alloy-metrics collector keeps that series from its kube-state-metrics scrape and Prometheus stores one series for each container start.

#### Scenario: The shared K8s check passes with the new name
- **WHEN** I run `KUSTOMIZE_ROOTS= HELM_CHARTS=helm/k8s-monitoring/test-chart PROMTOOL_RULES= TRIVY_IGNORE_FILE=helm/.trivyignore.yaml mise exec -- scripts/k8s-validate.sh all` on the branch of the change
- **THEN** The command exits with status 0 and its output holds `helm lint and helm template helm/k8s-monitoring/test-chart`
