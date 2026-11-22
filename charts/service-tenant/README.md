# service-tenant

The tenant of one service repository in the cluster. A trusted admin Application applies the chart
in the Argo CD project `services-admin`. The chart makes the namespaces of the service, the Argo CD
AppProject of the service and the guard rails of each namespace. The service Application then
deploys only namespaced kinds of an allow-list into those namespaces.

## Objects

| Object | Content |
| --- | --- |
| `Namespace` for each namespace of the entry | `pod-security.kubernetes.io/enforce` from `podSecurity` (default `restricted`). `warn` and `audit` are always `restricted`. The label `monitoring-scrape: "true"`, and the label `backup-client: "true"` when `backup` is `true`. The sync options `Prune=false,Delete=false`. |
| `AppProject` `<name>` in `argocd.namespace` | `sourceRepos`: only `repoURL`. `destinations`: only the namespaces of the entry on `argocd.destinationServer`. `clusterResourceWhitelist: []`. A `namespaceResourceWhitelist` allow-list, then `extraKinds`. `orphanedResources.warn: true`. The annotation `notifications.argoproj.io/subscribe.on-deployed.github`. |
| `NetworkPolicy` `default-deny-ingress` in each namespace | Type `Ingress` only, with no rule: no ingress. |
| `NetworkPolicy` `default-deny-egress` in each namespace | Type `Egress` only: DNS on UDP and TCP port 53 to the pods with `dns.podLabels` in `dns.namespace`. |
| `LimitRange` `default-resources` in each namespace | The `default` and `defaultRequest` CPU and memory of each container, from `limitRange`. |
| Traefik `Middleware` `security-headers` in each namespace | HSTS for one year with subdomains and no preload, `nosniff`, the frame option `SAMEORIGIN`, the referrer policy `strict-origin-when-cross-origin`, and a permissions policy that stops the camera, the microphone, the location, payments and USB. |

The allow-list of the AppProject has these kinds:

- `apps`: Deployment, StatefulSet. `batch`: Job, CronJob.
- Core: Service, ConfigMap, PersistentVolumeClaim, ServiceAccount.
- `networking.k8s.io`: Ingress, NetworkPolicy. `policy`: PodDisruptionBudget. `autoscaling`:
  HorizontalPodAutoscaler.
- `traefik.io`: Middleware. `monitoring.coreos.com`: PodMonitor, ServiceMonitor.
- `postgresql.cnpg.io`: Cluster, ScheduledBackup. `barmancloud.cnpg.io`: ObjectStore.
- `k8up.io`: Schedule, PodConfig, Restore.

The list has no Secret, no Role, no RoleBinding and no SecretStore. Thus the service cannot write a
Secret, give rights to a ServiceAccount, or read the Secrets of another namespace (devops-cli
ADR 0033).

## Network

Each NetworkPolicy has one type only. The network policy controller of k3s lets an egress rule of a
policy with the types `Ingress` and `Egress` admit traffic between two pods that the policy selects,
although the ingress rules of the policy deny it (dan-petty/devops-cli#6707). A policy with one type
does not have this problem.

A pod of a service namespace gets no ingress and reaches only the cluster DNS. NetworkPolicies add
to each other, so the service adds its own allow policies, also between its own pods. Write each
allow policy with one type, and make each egress rule as narrow as the ingress of its destination.

## Values

The values are the platform values of the consumer and one services entry. The consumer gives two
value files: its platform values, then the services entry of the service. With no services entry,
the chart renders no object. `values.schema.json` refuses an unknown key and a value of the wrong
form, and an entry that has only some of the required keys.

Platform values:

| Key | Default | Content |
| --- | --- | --- |
| `reservedNamespaces` | `kube-system`, `kube-public`, `kube-node-lease`, `default`, `argocd` | The namespaces that no entry can use. Add the platform namespaces of the cluster. |
| `reservedProjects` | `default`, `services-admin` | The AppProjects that no entry can replace. Add the AppProjects of the cluster. |
| `argocd.namespace` | `argocd` | The namespace of Argo CD, which holds the AppProject. No entry can use it. |
| `argocd.destinationServer` | `https://kubernetes.default.svc` | The cluster of the destinations. |
| `dns.namespace` | `kube-system` | The namespace of the cluster DNS. No entry can use it. |
| `dns.podLabels` | `k8s-app: kube-dns` | The labels of the DNS pods. Helm merges maps, so set `k8s-app: null` to remove the default label. |
| `limitRange.default` | `cpu: 500m`, `memory: 256Mi` | The default limits of each container. |
| `limitRange.defaultRequest` | `cpu: 50m`, `memory: 64Mi` | The default requests of each container. |

Keys of the services entry:

| Key | Required | Content |
| --- | --- | --- |
| `name` | Yes | The name of the service and of its AppProject. |
| `repoURL` | Yes | The git repository of the service. No glob and no `!`. |
| `path` | Yes | The folder of the manifests of the service in `repoURL`. |
| `targetRevision` | Yes | The branch, tag or commit that Argo CD deploys. |
| `namespaces` | Yes | The namespaces of the service, each with `name`, `podSecurity` (`restricted` or `baseline`, default `restricted`) and `backup` (default `false`). |
| `images` | No | The images that Argo CD Image Updater updates, each with `alias` and `image`. |
| `extraKinds` | No | Namespaced kinds, each with `group` and `kind`, that an admin reviewed. No glob. |

The chart does not read `path`, `targetRevision` and `images`. The schema checks them for the
Application of the service, which the consumer renders from the same entry.

```yaml
name: example
repoURL: https://git.example.com/example.git
path: deploy
targetRevision: main
namespaces:
  - name: example
  - name: example-db
    podSecurity: baseline
    backup: true
```

## Guards

The template `guards.yaml` stops the render when the entry:

- has a `name` of `reservedProjects`, because its AppProject would replace that project;
- has a namespace of `reservedNamespaces`, `argocd.namespace` or `dns.namespace`, or one namespace
  two times;
- has an extra kind `Secret`, `Role`, `RoleBinding`, `ClusterRole`, `ClusterRoleBinding`,
  `SecretStore` or `ClusterSecretStore`, in each group;
- has an extra kind of the group `generators.external-secrets.io` other than `Password`.

The guards stop mistakes in the services entry. They do not replace the review of a person: the
entry and the platform values are in one environment repository, where only a person merges.

## Tests

The unit tests are in `tests/`, and the values of the test render are in `ci/test-values.yaml`. The
K8s job of CI runs them (README.md of the repository, "Checks").

## Consumers

The ApplicationSet `service-tenants` of the base `k8s/bases/service-repos` renders the chart for
each services entry ([docs/service-repos.md](../../docs/service-repos.md)). Its planned consumer is
dan-petty/homelab#80.
