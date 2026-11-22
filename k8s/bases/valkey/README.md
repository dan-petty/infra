# Valkey base

The base `valkey` is one [Valkey](https://valkey.io/) store for a cache or a queue. It holds a
Deployment with one pod, a Service on port 6379, two NetworkPolicies and a ConfigMap with the
settings. Three components add parts to it:

| Component | Adds |
| --- | --- |
| [`valkey-persistence`](../../components/valkey-persistence/) | The PersistentVolumeClaim `valkey-data` for `/data`, so the files of Valkey stay after a restart. |
| [`valkey-exporter`](../../components/valkey-exporter/) | The `redis_exporter` sidecar `exporter` with the metrics on port 9121, and the NetworkPolicy `valkey-exporter-ingress`. |
| [`valkey-acl`](../../components/valkey-acl/) | The ACL users of an aclfile from the Secret `valkey-acl`. |

The test overlays are `k8s/tests/valkey` (the base alone), `k8s/tests/valkey-persistence` (a queue
store), `k8s/tests/valkey-exporter`, `k8s/tests/valkey-acl` and `k8s/tests/valkey-full` (all three
components).

## Consumers

None yet. The planned consumers are the Open WebUI store of dan-petty/homelab (dan-petty/homelab#88),
the queue store of a service repository and the Valkey stores of dan-petty/devops-cli.

## Use the base

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: example
resources:
  - https://github.com/dan-petty/infra//k8s/bases/valkey?ref=vX.Y.Z
components:
  - https://github.com/dan-petty/infra//k8s/components/valkey-persistence?ref=vX.Y.Z
configMapGenerator:
  - name: valkey
    behavior: merge
    files:
      - valkey.conf
```

Clients in the namespace connect to `valkey:6379` with the password of the Secret `valkey-auth`.

## Inputs

| Input | Needed | Content |
| --- | --- | --- |
| Namespace | Yes | The namespace of the store. Set it with `namespace:` in the overlay. |
| Secret `valkey-auth`, key `password` | Yes | The password of the Valkey user `default`. The consumer creates the Secret, so no password is in git. The password has no double quote, backslash or line break. The exporter of `valkey-exporter` uses the same key. |
| Label `valkey-client: "true"` | Yes, on each client pod | `valkey-ingress` admits only the pods of the namespace with this label, on port 6379. |
| ConfigMap `valkey`, key `valkey.conf` | No | The settings. The base file is a cache: no file on disk, `maxmemory 128mb` and `maxmemory-policy allkeys-lru`. Replace the file with a `configMapGenerator` of `behavior: merge`. Keep `port 6379` and `dir /data`, and add no `requirepass` or `bind` line. |
| Resources of the container `valkey` | No | Requests of 20m CPU and 64Mi memory, limits of 500m CPU and 256Mi memory. When you patch the memory limit, set `maxmemory` to about half of it: a fork that writes a snapshot or rewrites the append-only file needs memory. |
| Claim `valkey-data` | With `valkey-persistence` | 1Gi, `ReadWriteOnce`, of the default storage class. Patch `spec.resources.requests.storage` and `spec.storageClassName`. |
| Scraper namespace | With `valkey-exporter` | `valkey-exporter-ingress` admits the pods of the namespace `monitoring` to port 9121. Patch its `namespaceSelector` for another namespace. |
| Secret `valkey-acl`, key `users.acl` | With `valkey-acl` | The ACL users ("ACL users"). The consumer creates the Secret. |

The test overlay `k8s/tests/valkey-persistence` is a queue store: `valkey.conf` with
`appendonly yes`, `appendfsync everysec` and `maxmemory-policy noeviction`, and the claim of
`valkey-persistence`. At `maxmemory`, Valkey then refuses a write and evicts no job.

## Security

The pod meets the `restricted` Pod Security Standard. It runs as the user `valkey` of the image
(999) with the group 1000, with `runAsNonRoot`, the seccomp profile `RuntimeDefault`, no privilege
escalation and all capabilities dropped. The root file system is read-only, so trivy config finds no
KSV-0014. Valkey writes only to its volumes: `/data`, `/tmp` and the memory volume `/run/valkey`. The
pod gets no ServiceAccount token and no variables of the Services of the namespace.

The start script writes the password into a config file on `/run/valkey`, not onto the command
line, where the process list shows it. That file includes `valkey.conf` of the ConfigMap. Each image
has a tag and a digest in the field `newTag` of `images:`, in the `kustomization.yaml` of the base or
the component. Renovate updates both in infra, and a consumer gets them with a new release tag. A
consumer can replace an image, such as with a mirror, with `images:` of its own overlay.

The Deployment uses the strategy `Recreate`: one pod writes the data, and the old pod stops before
the new pod starts. Each rollout thus stops the store for a short time. The annotation
`ignore-check.kube-linter.io/no-rolling-update-strategy` gives the reason to kube-linter.

## Network policies

Each NetworkPolicy has one policy type, Ingress or Egress. The network policy controller of k3s
(kube-router) lets an egress rule of a policy with both types admit traffic between two pods that
the policy selects, also when its ingress rules refuse that traffic (dan-petty/devops-cli#6707). It
applies a policy of one type correctly.

| Policy | Type | Rule |
| --- | --- | --- |
| `valkey-ingress` | Ingress | The pods of the namespace with `valkey-client: "true"`, to TCP 6379. |
| `valkey-egress` | Egress | No egress. Valkey only answers, and the exporter reaches Valkey on localhost. |
| `valkey-exporter-ingress` (`valkey-exporter`) | Ingress | The pods of the namespace `monitoring`, to TCP 9121. |

A client pod with an Egress policy of its own needs a rule to the pods with
`app.kubernetes.io/name: valkey` on TCP 6379. Make that rule no wider than `valkey-ingress`.

## ACL users

`valkey-acl` mounts the key `users.acl` of the Secret `valkey-acl` at `/etc/valkey/users.acl`, and
starts `valkey-server` with `--aclfile /etc/valkey/users.acl`. The file has the format of the
[ACL file](https://valkey.io/topics/acl/) of Valkey.

- Valkey ignores `requirepass` when it reads an aclfile. Thus the file must define the user
  `default`: `user default on >PASSWORD ~* &* +@all` with the password of `valkey-auth`, or
  `user default off`. When the file has no user `default`, Valkey gives that user no password.
  Protected mode then refuses each client that does not connect from localhost.
- The exporter of `valkey-exporter` logs in as `default` with the password of `valkey-auth`. With
  `user default off`, give the exporter a user of its own: patch the variables `REDIS_USER` and
  `REDIS_PASSWORD` of the container `exporter`.
- The file is read-only, so `ACL SAVE` fails. Change the users in the Secret, then restart the pod.

## Two stores in one namespace

Give each overlay a `namePrefix` and the label `app.kubernetes.io/instance` with
`includeSelectors: true`, so the selectors of the two stores differ. Kustomize also adds that label
to the client selector of `valkey-ingress`, so each client pod also carries the label of its store.
A name prefix does not change a reference to a Secret that is not in the build. Thus patch the
names `valkey-auth` and `valkey-acl`, or use the same Secrets for both stores.

## The Valkey Helm chart

AGENTS.md of dan-petty/devops-cli, rule 3: use an open tool before you build. The open tool is the
official chart [valkey-io/valkey-helm](https://github.com/valkey-io/valkey-helm) (chart `valkey`
1.0.0 of 2026-11-13, BSD-3-Clause, maintained by valkey-io).

| Need | valkey-helm 1.0.0 | This base |
| --- | --- | --- |
| Render in the Kustomize root of a consumer | Helm only. Argo CD here runs Kustomize with no `--enable-helm` (`kustomize.buildOptions` is not set), so a Kustomize root cannot render the chart. | A Kustomize base and components. |
| NetworkPolicy | One policy with the types Ingress and Egress (`templates/netpolicy.yaml`), off by default. With kube-router, its egress rules admit traffic that its ingress rules refuse. | Ingress-only and Egress-only policies. |
| Image pin | A tag (the default is the `appVersion` 9.1.3), with no digest value. | A tag and a digest. |
| Settings | `extraConfig` text. | `valkey.conf` of the ConfigMap. |
| Persistence | `persistence.enabled`. | `valkey-persistence`, with the Argo CD sync options `Prune=false,Delete=false`. |
| Exporter | `metrics.enabled`: `redis_exporter` on 9121, with a ServiceMonitor or a PodMonitor. | `valkey-exporter`. |
| ACL users | `auth.aclUsers` and `auth.usersExistingSecret`. | `valkey-acl`, with one Secret key. |
| Restricted context | A read-only root file system, user 1000. | The same, with the user of the image (999). |
| Replicas, Sentinel and TLS | Yes. | No: one pod. |

Result: the chart covers the workload, the exporter, persistence and ACL users, and it has more
(replicas, Sentinel and TLS). It does not fit the consumers now, because a Kustomize root cannot
render it. The chart fits only after a later change that the owner approves turns on
`--enable-helm` in Argo CD. Then keep its NetworkPolicy off and add policies of one type.
