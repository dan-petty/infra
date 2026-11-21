# Kustomize components

Each folder `k8s/components/<component>/` is one Kustomize component (`kind: Component`): a part
that a consumer adds to its own overlay with `components:`. A component holds no value of one
environment. The Prometheus rules of a component are in `rules/*.rules.yaml`, and the K8s job of
CI checks them with `promtool check rules`.

Kustomize cannot build a component alone. So each component has a test overlay in
`k8s/tests/<component>/` that adds it to a base, with `example.com` and RFC 5737 values.

The README of each component names its consumers.

| Component | Content | Consumers |
| --- | --- | --- |
| `example` | A ConfigMap of one Prometheus rule file: the fixture of the checks. | None. |

A consumer pins a component at a release tag of infra:

```yaml
components:
  - https://github.com/dan-petty/infra//k8s/components/<component>?ref=vX.Y.Z
```
