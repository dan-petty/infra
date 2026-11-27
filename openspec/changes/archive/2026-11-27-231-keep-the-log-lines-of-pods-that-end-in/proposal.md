# Proposal: #231

## Why

The values template turns on `podLogsViaLoki` with the collector alloy-logs, and keeps the chart default `onlyGatherNewLogLines: true`. The chart writes it as `tail_from_end = true` of `loki.source.file "pod_logs"`: Alloy reads a file with no stored position from its end, and `local.file_match "pod_logs"` finds new files each 10 seconds. So a pod that writes its whole log before the next match loses each line. On dan-petty/homelab, the descheduler Jobs of 2026-11-27 (about 5 s each) have no line in Loki (dan-petty/homelab#583).

## What Changes

- `helm/k8s-monitoring/values.yaml` sets `podLogsViaLoki.onlyGatherNewLogLines: false`.
- `helm/k8s-monitoring/test-chart/tests/pod_logs_test.yaml` tests the rendered `tail_from_end` and the host path of the read positions.
- `helm/README.md` names the setting and the chart version 4.6.2.

## Capabilities

- `k8s-monitoring-pod-logs` (new): a new pod log file is read from its first line, and the read positions stay on the node.

## Impact

- A consumer gets the change when it moves its infra tag to a release that holds it.
- At the first start after the change, Alloy resumes each file whose position it stored, so it sends no old line again. Only a file that it never saw starts at its first line.
- The change fits one pull request.

## Feasibility

- k8s-monitoring 4.6.2, `charts/feature-pod-logs-via-loki/templates/_gathering.alloy.tpl`: `tail_from_end = {{ .Values.onlyGatherNewLogLines }}`; the default in `values.yaml` of that subchart is `true`.
- The render of the test chart on `main` (`scripts/k8s-validate.sh all`) holds `tail_from_end = true` in `ConfigMap-k8s-monitoring-alloy-logs.yaml`.
- The Alloy object of alloy-logs renders `storagePath: /var/lib/alloy` and the host path volume `alloy-storage` (preset `host-storage`). On dan-petty/homelab the live alloy-logs DaemonSet runs with `--storage.path=/var/lib/alloy` on that host path.
- The first test of `pod_logs_test.yaml` failed on `main` with `tail_from_end = true`; the second passed, because the host path already exists.

## Existing Tool Considered

The chart value `onlyGatherNewLogLines` of k8s-monitoring, and the read positions of Alloy's `loki.source.file`. The change adds no code.
