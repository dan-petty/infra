# Kustomize bases

Each folder `k8s/bases/<base>/` is one Kustomize base: a set of Kubernetes manifests that a
consumer builds into its own overlay. A base holds no value of one environment. It uses the
placeholder `<domain>` for a domain, and the consumer sets its own value in a patch.

Each base has a test overlay in `k8s/tests/<base>/`, with `example.com` and RFC 5737 values. The K8s
job of CI builds the test overlay and checks the result (README.md, "Checks").

The README of each base names its consumers.

| Base | Content | Consumers |
| --- | --- | --- |
| `example` | A ConfigMap and a PersistentVolumeClaim: the fixture of the checks. | None. |
| [`valkey`](valkey/README.md) | One Valkey store for a cache or a queue: a Deployment, a Service, two NetworkPolicies and the settings in a ConfigMap. | None yet. Planned: dan-petty/homelab#88, a service queue store and the stores of devops-cli. |

A consumer pins a base at a release tag of infra:

```yaml
resources:
  - https://github.com/dan-petty/infra//k8s/bases/<base>?ref=vX.Y.Z
```
