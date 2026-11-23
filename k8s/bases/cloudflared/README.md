# cloudflared

The base `cloudflared` deploys two Cloudflare tunnel connectors with anti-affinity, a PodDisruptionBudget, and a NetworkPolicy. It reads the tunnel token from Secret `cloudflared-token`.

## Tool comparison

The upstream chart `cloudflare-tunnel-remote` from `cloudflare/helm-charts` was evaluated. It does not provide the default 2-replica set with anti-affinity, the fixed Secret name `cloudflared-token` required by the cluster secrets restart hook, or a PodDisruptionBudget. This Kustomize base is maintained in-repo instead.

## Consumers

- `dan-petty/homelab` (`dan-petty/homelab#89`).
