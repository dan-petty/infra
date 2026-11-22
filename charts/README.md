# Helm charts

Each folder `charts/<chart>/` is one Helm chart that infra writes. A chart holds no value of one
environment: its default values use `example.com`, and the consumer sets its own values.

Each chart has:

- `ci/*-values.yaml`: the values of each test render. `helm lint --strict` and `helm template`
  run once for each file.
- `tests/*_test.yaml`: the unit tests of [helm-unittest](https://github.com/helm-unittest/helm-unittest).

The K8s job of CI lints, renders and tests each chart, and checks the rendered manifests (README.md,
"Checks"). To add a chart to CI, add its folder to the input `helm-charts` of the job `k8s` in
`.github/workflows/ci.yml`.

The README of each chart names its consumers.

| Chart | Content | Consumers |
| --- | --- | --- |
| `example` | One ConfigMap: the fixture of the checks. | None. |
| [`service-tenant`](service-tenant/README.md) | The tenant of one service repository: its Namespaces, its Argo CD AppProject, and the default-deny NetworkPolicies, the LimitRange and the Traefik Middleware `security-headers` of each namespace. | None yet. dan-petty/infra#11 plans the first consumer. |
