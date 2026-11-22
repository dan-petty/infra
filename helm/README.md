# Helm values templates

Each folder `helm/<chart>/` holds the values template `values.yaml` of one upstream chart: the
settings that are true for each cluster, such as security contexts, probes and alert rules. A
values template holds no value of one environment. The consumer gives the template to the upstream
chart, for example as a value file of an Argo CD Application, and adds its own values.

Each values template has a test chart `helm/<chart>/test-chart/` that pins the upstream chart at one
exact version, as its one dependency in its `Chart.yaml`. `Chart.lock` holds the digest of the
dependencies, and `helm dependency build` downloads the chart into `charts/`, which git ignores.
Take the dependency from the OCI repository of the chart when it has one: `helm dependency build`
of Helm 4 refuses an HTTP repository that `helm repo add` did not add. `helm lint --strict` needs a
`values.yaml` and a `templates/` folder in the test chart.

The K8s job of CI lints, renders and checks the test chart (README.md, "Checks").
`scripts/k8s-validate.sh` knows a test chart by its folder name `test-chart`. It puts the values
template `../values.yaml` under the name of the dependency with yq, as Helm gives values to a
dependency, and gives that file to `helm lint`, `helm template` and `helm unittest`. The release has
the name of the dependency, so the objects have the names of an install with that release name.
The unit tests of the template are in `test-chart/tests/`.

## Templates

| Template | Upstream chart | Content | Consumers |
| --- | --- | --- | --- |
| [`external-secrets`](external-secrets/values.yaml) | `external-secrets` 2.15.0 from `oci://ghcr.io/external-secrets/charts` | External Secrets Operator with its CRDs and the `PushSecret` controller: the Pod Security level `restricted`, requests, limits and probes, the metrics port 8080, the webhook port 10250, and one NetworkPolicy of the type `Ingress` for each pod (devops-cli ADR 0033). | dan-petty/homelab#82. |

The upstream NetworkPolicies of `external-secrets` have the types `Ingress` and `Egress` in one
policy, so the template turns them off. The network policy controller of k3s lets an egress rule of
such a policy admit traffic that its ingress rules deny (dan-petty/devops-cli#6707). The template
adds one policy of one type for each pod through `extraObjects`. The egress destinations, such as
the API server and the providers, are values of one cluster, so the consumer adds the egress
policies. Helm replaces a list, so a consumer that sets `extraObjects` gives the policies of the
template again.

## trivy judgments

`.trivyignore.yaml` holds the written judgments of the trivy config scan of the K8s renders. Each
entry names one finding ID on the file of one object of one release, with a reason and an expiry
date. Only the owner accepts a CRITICAL finding. The K8s job of CI gives the file to the input
`trivy-ignorefile` of `k8s-validate.yml`, and `tests/test-k8s-validate.sh` checks that each entry
admits only its finding on its object.

| Finding | Object | Expiry |
| --- | --- | --- |
| KSV-0041 | ClusterRole `external-secrets-controller`: the controller writes the Secret of each ExternalSecret in each namespace. | 2026-12-22 |
| KSV-0041 | ClusterRole `external-secrets-cert-controller`: the cert-controller writes the certificate Secret of the webhook. | 2026-12-22 |
| KSV-0114 | ClusterRole `external-secrets-cert-controller`: the cert-controller writes the CA bundle into the ValidatingWebhookConfigurations of ESO. | 2026-12-22 |
