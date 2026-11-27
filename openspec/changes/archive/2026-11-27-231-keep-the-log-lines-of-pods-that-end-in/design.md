# Design: #231

## Decisions

### Read new files from their first line

`onlyGatherNewLogLines: false` makes the chart write `tail_from_end = false`. Alloy reads a file with a stored position from that position in both modes, so the value acts only on a file with no position: a new pod, or a file that Alloy never saw.

## Rejected alternatives

- A shorter `sync_period` of `local.file_match`: a file found 1 s after it was written still starts at its end, so a pod that ends in 1 s still loses its lines (`tail_from_end` of `loki.source.file`).
- `podLogsViaKubernetesApi` (the chart's `feature-pod-logs-via-kubernetes-api`): it replaces the node file reader of the preset `filesystem-log-reader`, and reads each log through the API server.
- A value in each consumer: each consumer of the template has the same gap, and `helm/README.md` makes the template the one place for a shared setting.
