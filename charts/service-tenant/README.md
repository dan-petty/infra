# service-tenant

The tenant of one service repository in the cluster. A trusted admin Application applies the chart
in the Argo CD project `services-admin`. The chart makes the namespaces of the service, the Argo CD
AppProject of the service and the guard rails of each namespace. The service Application then
deploys only namespaced kinds of an allow-list into those namespaces.

## Objects

| Object | Content |
| --- | --- |
| `Namespace` for each namespace of the entry | `pod-security.kubernetes.io/enforce` from `podSecurity` (default `restricted`). `warn` and `audit` are always `restricted`. The label `monitoring-scrape: "true"`, and the label `backup-client: "true"` when `backup.quotaGiB` is set. The sync options `Prune=false,Delete=false`. |
| `AppProject` `<name>` in `argocd.namespace` | `sourceRepos`: only `repoURL`. `destinations`: only the namespaces of the entry on `argocd.destinationServer`. `clusterResourceWhitelist: []`. A `namespaceResourceWhitelist` allow-list, then `extraKinds`. `orphanedResources.warn: true`. The annotation `notifications.argoproj.io/subscribe.on-deployed.github`. |
| `NetworkPolicy` `default-deny-ingress` in each namespace | Type `Ingress` only, with no rule: no ingress. |
| `NetworkPolicy` `default-deny-egress` in each namespace | Type `Egress` only: DNS on UDP and TCP port 53 to the pods with `dns.podLabels` in `dns.namespace`. |
| `LimitRange` `default-resources` in each namespace | The `default` and `defaultRequest` CPU and memory of each container, from `limitRange`. |
| Traefik `Middleware` `security-headers` in each namespace | HSTS for one year with subdomains and no preload, `nosniff`, the frame option `SAMEORIGIN`, the referrer policy `strict-origin-when-cross-origin`, and a permissions policy that stops the camera, the microphone, the location, payments and USB. |
| The objects of the secret store, when `secrets.store` is `true` | The store namespace `<name>-secrets`, and a `ServiceAccount` `eso-store` and a `SecretStore` `store` in each namespace of the entry ("Secrets"). |
| The objects of the backup bucket, when a namespace sets `backup.quotaGiB` | The store set in `object-store` (`Bucket`, `S3Identity`, `S3Policy`, `S3PolicyBinding`, `S3Credentials`), the store `SecretStore` and `ServiceAccount` in `object-store`, the `RoleBinding` in `<name>-secrets`, `PushSecret`, and the `ExternalSecret` in the namespace ("Backup"). |

The allow-list of the AppProject has these kinds:

- `apps`: Deployment, StatefulSet. `batch`: Job, CronJob.
- Core: Service, ConfigMap, PersistentVolumeClaim, ServiceAccount.
- `networking.k8s.io`: Ingress, NetworkPolicy. `policy`: PodDisruptionBudget. `autoscaling`:
  HorizontalPodAutoscaler.
- `traefik.io`: Middleware. `monitoring.coreos.com`: PodMonitor, ServiceMonitor.
- `postgresql.cnpg.io`: Cluster, ScheduledBackup. `barmancloud.cnpg.io`: ObjectStore.
- `k8up.io`: Schedule, PodConfig, Restore.
- With the secret store only: `external-secrets.io`: ExternalSecret, PushSecret.
  `generators.external-secrets.io`: Password.

The list has no Secret, no Role, no RoleBinding, no SecretStore and no ESO generator but Password.
Thus the service cannot write a Secret, give rights to a ServiceAccount, read the Secrets of
another namespace, or send a value out of the cluster (devops-cli ADR 0033). The Password generator
makes a random value in the cluster. Another generator, such as the Webhook generator, can send
data to an endpoint.

## Secrets

An entry with `secrets.store: true` gets one secret store of External Secrets Operator (ESO). The
cluster has the operator, for example from the values template `helm/external-secrets` of infra.

| Object | Content |
| --- | --- |
| `Namespace` `<name>-secrets` | The store namespace. `pod-security.kubernetes.io/enforce`, `warn` and `audit` are `restricted`. The sync options `Prune=false,Delete=false`. No pod runs in it. |
| `Role` `eso-store` in the store namespace | `get`, `list`, `watch`, `create` and `update` on `secrets`, and nothing more. |
| `ServiceAccount` `eso-store` in each namespace of the entry | `automountServiceAccountToken: false`. ESO requests a token of it for the SecretStore. |
| `SecretStore` `store` in each namespace of the entry | The Kubernetes provider of ESO: `remoteNamespace: <name>-secrets`, `server.url: https://kubernetes.default.svc`, the CA of the ConfigMap `kube-root-ca.crt`, and `auth.serviceAccount.name: eso-store`. |
| `RoleBinding` `eso-store-<namespace>` in the store namespace for each namespace of the entry | Binds the Role `eso-store` to the ServiceAccount `eso-store` of that namespace. |

The Kubernetes provider reads one remote namespace, and a store can read each Secret of it. Thus
each service has its own store namespace, and the chart makes no ClusterSecretStore. All the
namespaces of a service share its store namespace. The store namespace is no destination of the
AppProject of the service, and the AppProject has no SecretStore and no RBAC kind, so the service
can point no store at another namespace. The service reads and writes its store only through the
SecretStore `store`, with ExternalSecret and PushSecret objects. A remote key in the store
namespace is `<namespace>.<secret>` ([docs/service-repos.md](../../docs/service-repos.md),
"Secrets").

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
| `namespaces` | Yes | The namespaces of the service, each with `name`, `podSecurity` (`restricted` or `baseline`, default `restricted`) and optional `backup.quotaGiB`. |
| `images` | No | The images that Argo CD Image Updater updates, each with `alias` and `image`. |
| `extraKinds` | No | Namespaced kinds, each with `group` and `kind`, that an admin reviewed. No glob. |
| `secrets.store` | No | `true` gives the service its secret store ("Secrets"). Default `false`. |

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
    backup:
      quotaGiB: 10
```

## Backup

When a namespace sets `backup.quotaGiB`, the chart provisions a backup bucket and credentials. The
entry must also set `secrets.store: true`.

| Object | Content |
| --- | --- |
| `Bucket` `backups-<namespace>` in `object-store` | Quota from `backup.quotaGiB`, `reclaimPolicy: Retain`, no expiration rule, no anonymous access. |
| `S3Identity`, `S3Policy`, `S3PolicyBinding`, `S3Credentials` in `object-store` | Access scoped only to bucket `backups-<namespace>`. The operator makes the key pair and owns its Secret `object-store-backup` (`<namespace>-object-store-backup` when 2 or more namespaces have a backup). No other object writes that Secret. |
| `SecretStore` `store` and `ServiceAccount` `eso-store` in `object-store` | Points to the store namespace `<name>-secrets`. |
| `RoleBinding` `eso-store-object-store` in `<name>-secrets` | Authorizes `eso-store` in `object-store` to read and write secrets. |
| `PushSecret` in `object-store` | Writes the key pair that the SeaweedFS operator made to remote key `<namespace>.object-store-backup`, with `updatePolicy: Replace`. |
| `ExternalSecret` `object-store-backup` in tenant namespace | Reads back remote key `<namespace>.object-store-backup` into Secret `object-store-backup`. |

## Guards

The template `guards.yaml` stops the render when the entry:

- has a `name` of `reservedProjects`, because its AppProject would replace that project;
- has a namespace of `reservedNamespaces`, `argocd.namespace` or `dns.namespace`, or one namespace
  two times;
- sets `backup.quotaGiB` when `secrets.store` is false;
- has the store, and its store namespace `<name>-secrets` has more than 63 characters (a `name` of
  more than 55 characters), is a namespace of the entry, or is a namespace of
  `reservedNamespaces`, `argocd.namespace` or `dns.namespace`;
- has an extra kind `Secret`, `Role`, `RoleBinding`, `ClusterRole`, `ClusterRoleBinding`,
  `SecretStore` or `ClusterSecretStore`, in each group;
- has an extra kind of the group `generators.external-secrets.io` other than `Password`.

The guards stop mistakes in the services entry. They do not replace the review of a person: the
entry and the platform values are in one environment repository, where only a person merges.

## Tests

The unit tests are in `tests/`. The values of the test renders are in `ci/test-values.yaml` and,
with the secret store, in `ci/store-values.yaml`. The K8s job of CI runs them (README.md of the
repository, "Checks").

## Consumers

The ApplicationSet `service-tenants` of the base `k8s/bases/service-repos` renders the chart for
each services entry ([docs/service-repos.md](../../docs/service-repos.md)). Its planned consumer is
dan-petty/homelab#80.
