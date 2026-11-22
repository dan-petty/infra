# Documents

This folder holds the documents of infra that are too long for the README of a folder, such as a
procedure that is true for more than one template. Each document applies to all consumers. A
document holds no value of one environment.

| Document | Content |
| --- | --- |
| [service-repos.md](service-repos.md) | The base `k8s/bases/service-repos`: the services entry, the consumer patches, the objects that a service repository owns, and the secret store with its remote key rule. |

The README of each template folder tells the content and the consumers of its templates. The
README.md in the repository root tells the layout, the checks and how a consumer pins a release.
