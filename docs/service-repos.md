# Service repositories

The Kustomize base `k8s/bases/service-repos` deploys each service repository from one services
entry. A services entry is one YAML file in the folder `k8s/services/` of the environment repository
of the consumer. Only a person merges in the environment repository, so it is the source of truth of
each service. The platform holds no row, constant, namespace, alert or dashboard of one service:
these are in the services entry and in the service repository.

The base uses the chart [`charts/service-tenant`](../charts/service-tenant/README.md) of infra.

## Objects

| Object | Content |
| --- | --- |
| `ApplicationSet` `service-tenants` | One Application `tenant-<name>` for each entry, in the AppProject `services-admin`. It renders the chart `charts/service-tenant` of infra at the release tag of the base, with two value files of the environment repository: the platform values `k8s/argocd/services/tenant-values.yaml`, then the entry file. The sync option `FailOnSharedResource=true` stops the sync when another Application has one of the objects, so two entries cannot take one namespace. |
| `ApplicationSet` `service-workloads` | One Application `<name>` for each entry, in the AppProject `<name>` that the chart makes. It deploys the folder `path` of `repoURL` at `targetRevision` into the first namespace of the entry, with automated sync (prune and selfHeal) and retry. It has the label `app.kubernetes.io/part-of: service-repos`, and the annotations of Image Updater when the entry has images. |
| `AppProject` `services-admin` | The project of the tenant Applications. `sourceRepos`: infra and the environment repository. `clusterResourceWhitelist`: only `Namespace`. `namespaceResourceWhitelist`: the kinds that the chart renders: `AppProject`, `NetworkPolicy`, `LimitRange` and the Traefik `Middleware`, and the `ServiceAccount`, `Role`, `RoleBinding` and `SecretStore` of the secret store ("Secrets"). `destinations`: `argocd`, which holds the AppProject of each service, and `*` with a deny destination `!<namespace>` for each reserved namespace. |
| `ImageUpdater` `service-repos` in `argocd` | `namePattern: "*"`, a label selector on `app.kubernetes.io/part-of: service-repos`, and `useAnnotations: true`. It has no `images`, `commonUpdateSettings` or `writeBackConfig`. |

A new kind of the chart needs a new row in the allow-list of `services-admin`.
`tests/test-service-repos.sh` fails when `services-admin` refuses an object of the chart.

## Settings of the ApplicationSets

Each ApplicationSet has a Git files generator over `k8s/services/*.yaml`, and these settings:

- `goTemplate: true` and `goTemplateOptions: ["missingkey=error"]`. A template that reads a key that
  an entry does not have stops the render of the ApplicationSet. Thus the templates read only the
  required keys. Only the `templatePatch` of `service-workloads` reads the optional key `images`,
  under the guard `{{- if hasKey . "images" }}`.
- `pathParamPrefix: file`. With `goTemplate`, the Git files generator of Argo CD v3.6.2 writes the
  path of the entry file into the param `path`, over the key `path` of the entry
  (`applicationset/generators/repo_path_utils.go`). With the prefix, the template reads the path
  of the file as `{{ .file.path.path }}/{{ .file.path.filename }}`, and the key `path` of the entry
  stays.
- `syncPolicy.preserveResourcesOnDeletion: true`. When an entry goes, Argo CD deletes its two
  Applications and keeps their resources. With this option, Argo CD adds no resources finalizer to
  the Applications, and the templates have none: a finalizer in the template deletes the resources
  with the Application. To remove the resources of a service, a person deletes them after the
  entry goes: the namespaces of the entry and the AppProject `<name>` in `argocd`.
- `service-workloads` has `ignoreApplicationDifferences` for `/spec/source/kustomize/images`. Image
  Updater writes the digest of each image into this field, and the ApplicationSet does not write
  over it.

The AppProject of the chart has the on-deployed subscription of Argo CD Notifications. Thus the
service Application has no subscription annotation.

The service Application uses the AppProject `<name>` that the tenant Application makes. Until the
tenant Application syncs, Argo CD shows an error on the service Application. The error goes when
the AppProject exists.

## Services entry

Each file in `k8s/services/` holds one services entry: one YAML object, not a list. The schema of
the chart (`charts/service-tenant/values.schema.json`) checks the entry and refuses an unknown key.
The tenant Application renders the chart with the entry file, so an entry that the schema refuses
stops the sync of `tenant-<name>`.

| Key | Required | Content |
| --- | --- | --- |
| `name` | Yes | The name of the service: the name of the Applications `<name>` and `tenant-<name>`, and of the AppProject of the service. No other Application in the namespace `argocd` can have this name. It is no AppProject of the cluster (`reservedProjects`): the chart refuses the entry for `tenant-<name>`, and the selector of `service-workloads` makes no Application `<name>`. |
| `repoURL` | Yes | The git repository of the service. |
| `path` | Yes | The folder of the manifests of the service in `repoURL`. For image updates, this is a Kustomize folder. |
| `targetRevision` | Yes | The branch, tag or commit that Argo CD deploys. |
| `namespaces` | Yes | The namespaces of the service, each with `name`, `podSecurity` and `backup` (charts/service-tenant/README.md, "Values"). The first namespace is the destination of the service Application. |
| `images` | No | The images that Argo CD Image Updater updates, each with `alias` and `image`. `image` names the tag that Image Updater follows, such as `registry.example.com/example/web:main`. |
| `extraKinds` | No | Namespaced kinds, each with `group` and `kind`, that an admin reviewed. The chart adds them to the AppProject of the service. |
| `secrets` | No | `store: true` gives the service its secret store ("Secrets"). Default `store: false`. |

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
images:
  - alias: web
    image: registry.example.com/example/web:main
extraKinds:
  - group: monitoring.coreos.com
    kind: PrometheusRule
secrets:
  store: true
```

## Images

With `useAnnotations: true`, Image Updater v1.4.0 uses only `namePattern` and `labelSelectors` of
the ImageUpdater object. It reads the update settings from the `argocd-image-updater.argoproj.io/*`
annotations of each Application (`docs/configuration/applications.md` of Image Updater). For an
entry with one or more images, the `templatePatch` of `service-workloads` writes these annotations:

| Annotation | Value |
| --- | --- |
| `argocd-image-updater.argoproj.io/image-list` | `<alias>=<image>` for each image, separated by commas. |
| `argocd-image-updater.argoproj.io/<alias>.update-strategy` | `digest`: Image Updater follows the digest of the tag that `image` names. |
| `argocd-image-updater.argoproj.io/write-back-method` | `argocd`: Image Updater writes the digest into `spec.source.kustomize.images` of the Application, and writes nothing into git. |

The ignore of `/spec/source/kustomize/images` keeps only the field of a Kustomize source. Thus a
service with images has a Kustomize folder at `path`. Two ImageUpdater objects that select one
Application write over each other. Thus no other ImageUpdater object selects the label
`app.kubernetes.io/part-of: service-repos` or the name of an entry.

## Consumer patches

The consumer builds the base at a release tag of infra into its own overlay:

```yaml
resources:
  - https://github.com/dan-petty/infra//k8s/bases/service-repos?ref=vX.Y.Z
```

The release tag of the base also sets the release of the chart: the release pull request of infra
writes the new tag on the line `targetRevision` of the chart source in
`k8s/bases/service-repos/applicationsets.yaml`.

| Value | Default of the base | Patch |
| --- | --- | --- |
| The URL of the environment repository | `https://git.example.com/environment.git` | `spec.generators[0].git.repoURL` of the two ApplicationSets, `spec.template.spec.sources[1].repoURL` of `service-tenants`, and `spec.sourceRepos[1]` of `services-admin`. |
| The revision of the environment repository | `HEAD` | `spec.generators[0].git.revision` of the two ApplicationSets, and `spec.template.spec.sources[1].targetRevision` of `service-tenants`. |
| The entry files | `k8s/services/*.yaml` | `spec.generators[0].git.files[0].path` of the two ApplicationSets. |
| The platform values | `k8s/argocd/services/tenant-values.yaml` | `spec.template.spec.sources[0].helm.valueFiles[0]` of `service-tenants`. |
| The reserved namespaces | `kube-system`, `kube-public`, `kube-node-lease`, `default` | Add a destination `namespace: '!<namespace>'` to `spec.destinations` of `services-admin` for each platform namespace of the cluster. Do not deny `argocd`: a deny destination refuses a namespace although another destination admits it. |
| The reserved projects | `default`, `services-admin` | Add each AppProject of `reservedProjects` to `values` of the `NotIn` expression of `spec.generators[0].selector` of `service-workloads`. |
| The cluster | `https://kubernetes.default.svc` | `server` of each destination of `services-admin` and of the two templates. |

The platform values file holds the platform values of the chart (charts/service-tenant/README.md,
"Values"). Give `reservedNamespaces` the same platform namespaces as the deny destinations, and
give `reservedProjects` the AppProjects of the cluster. The test overlay
`k8s/tests/service-repos` has an example of the deny patch:

```yaml
patches:
  - target:
      kind: AppProject
      name: services-admin
    patch: |-
      - op: add
        path: /spec/destinations/-
        value:
          server: https://kubernetes.default.svc
          namespace: '!monitoring'
```

## Service ownership

The service repository holds all the objects of one service under `path`. The service Application
deploys only the namespaced kinds of the allow-list of the chart and the `extraKinds` of the entry
(charts/service-tenant/README.md, "Objects"). The service repository owns:

- Its manifests: the workloads, Services, ConfigMaps, PersistentVolumeClaims and Ingresses of the
  service.
- Its NetworkPolicy allow rules. The chart makes a default-deny policy in each namespace, so the
  service adds each allow rule that it needs, also between its own pods.
- Its External Secrets Operator objects: with `secrets.store: true`, its `ExternalSecret` and
  `PushSecret` objects and its `Password` generators ("Secrets"). The chart refuses `Secret`,
  `SecretStore` and each ESO generator but `Password` in `extraKinds`.
- Its alert rules, such as a `PrometheusRule` in `extraKinds`, and its dashboards.
- Its backups, such as a k8up `Schedule` or a CloudNativePG `ScheduledBackup`, in a namespace with
  `backup: true`.

## Secrets

An entry with `secrets.store: true` gets the store namespace `<name>-secrets` and the SecretStore
`store` in each of its namespaces (charts/service-tenant/README.md, "Secrets"). The service
repository holds its `ExternalSecret`, `PushSecret` and `Password` objects. The store namespace
holds the values that must stay when a namespace of the service is deleted and made again, and the
values that a person types.

### Remote key rule

A remote key in the store namespace is `<namespace>.<secret>`: the namespace of the service that
uses the value, a dot, and the name of the Secret in that namespace. The Kubernetes provider of ESO
reads the remote key as the name of a Secret in the store namespace, and `property` as a key of the
data of that Secret.

All the namespaces of a service share its store namespace. A `PushSecret` with
`updatePolicy: IfNotExists` writes a remote Secret only when it does not exist. Thus two
namespaces that push one remote key write one remote Secret, and the second namespace gets the
value of the first. With the namespace in the remote key, each namespace has its own remote Secret.

### A generated value

A value that can change, such as a session key: an `ExternalSecret` makes the Secret from a
`Password` generator, with no store. `refreshPolicy: CreatedOnce` makes the value one time. A
namespace that is made again gets a new value.

```yaml
apiVersion: generators.external-secrets.io/v1alpha1
kind: Password
metadata:
  name: session-key
  namespace: example
spec:
  length: 32
  symbols: 0
  noUpper: false
  allowRepeat: true
---
apiVersion: external-secrets.io/v1
kind: ExternalSecret
metadata:
  name: session-key
  namespace: example
spec:
  refreshPolicy: CreatedOnce
  target:
    name: session-key
  dataFrom:
    - sourceRef:
        generatorRef:
          apiVersion: generators.external-secrets.io/v1alpha1
          kind: Password
          name: session-key
```

### A value that must never change

A value that must never change, such as the password of a database with data or an encryption key:
a `PushSecret` writes a generated value into the store with `updatePolicy: IfNotExists`, and an
`ExternalSecret` reads it back. The store keeps the value when the namespace is deleted, so the
namespace that is made again gets the same value. `deletionPolicy: None` keeps the remote Secret
when the `PushSecret` is deleted.

```yaml
apiVersion: generators.external-secrets.io/v1alpha1
kind: Password
metadata:
  name: db-password
  namespace: example-db
spec:
  length: 32
  symbols: 0
  noUpper: false
  allowRepeat: true
---
apiVersion: external-secrets.io/v1alpha1
kind: PushSecret
metadata:
  name: db-password
  namespace: example-db
spec:
  refreshInterval: 1h
  updatePolicy: IfNotExists
  deletionPolicy: None
  secretStoreRefs:
    - kind: SecretStore
      name: store
  selector:
    generatorRef:
      apiVersion: generators.external-secrets.io/v1alpha1
      kind: Password
      name: db-password
  data:
    - match:
        secretKey: password
        remoteRef:
          remoteKey: example-db.db-password
          property: password
---
apiVersion: external-secrets.io/v1
kind: ExternalSecret
metadata:
  name: db-password
  namespace: example-db
spec:
  refreshInterval: 1h
  secretStoreRef:
    kind: SecretStore
    name: store
  target:
    name: db-password
  data:
    - secretKey: password
      remoteRef:
        key: example-db.db-password
        property: password
```

### A typed value

A value that a person types, such as the token of a service outside the cluster: the person writes
the Secret `example.mail-token` with the key `token` into the store namespace `example-secrets`,
for example from the sensitive values of the consumer. An `ExternalSecret` of the service reads it.

```yaml
apiVersion: external-secrets.io/v1
kind: ExternalSecret
metadata:
  name: mail-token
  namespace: example
spec:
  refreshInterval: 1h
  secretStoreRef:
    kind: SecretStore
    name: store
  target:
    name: mail-token
  data:
    - secretKey: token
      remoteRef:
        key: example.mail-token
        property: token
```

## Checks

The K8s job of CI builds the test overlay `k8s/tests/service-repos` into `kubeconform -strict`,
with the CRD schemas of the datreeio CRDs-catalog. The job K8s templates runs
`tests/test-service-repos.sh` (README.md, "Checks"). The test checks the fields of the rendered
overlay. It then renders the templates of the two ApplicationSets with `helm template` for each
entry in `k8s/tests/service-repos/services/`, checks each Application with kubeconform, and renders
the chart with the value files of each tenant Application.

Only the ApplicationSet controller runs the generators, and `argocd appset generate` needs an Argo
CD server. `helm template` also runs Go templates with the sprig functions, but it has no
`missingkey=error`: a missing key gives an empty string. Thus the test refuses an empty string in
an Application.
