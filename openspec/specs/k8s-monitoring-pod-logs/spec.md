# k8s-monitoring-pod-logs Specification

## Purpose

The pod logs that the values template of k8s-monitoring collects with the alloy-logs DaemonSet: which lines of a pod log file it reads, and where it keeps the read positions.

## Requirements

### Requirement: A new pod log file is read from its first line
The values template SHALL set `podLogsViaLoki.onlyGatherNewLogLines: false`, so that `loki.source.file "pod_logs"` of the alloy-logs configuration has `tail_from_end = false`, and a pod that ends before the next file match keeps its lines.

#### Scenario: The rendered configuration reads from the first line
- **WHEN** `helm unittest` runs `helm/k8s-monitoring/test-chart/tests/pod_logs_test.yaml`.
- **THEN** The ConfigMap `k8s-monitoring-alloy-logs` holds `loki.source.file "pod_logs"` with `tail_from_end = false`.

### Requirement: The read positions stay on the node
The Alloy object of alloy-logs SHALL keep its storage path `/var/lib/alloy` on a host path of the node, so that a restart resumes each known file at its position.

#### Scenario: The rendered Alloy object mounts the host path
- **WHEN** `helm unittest` runs `helm/k8s-monitoring/test-chart/tests/pod_logs_test.yaml`.
- **THEN** The Alloy object `k8s-monitoring-alloy-logs` has `spec.alloy.storagePath: /var/lib/alloy` and the volume `alloy-storage` with the host path `/var/lib/alloy`.
