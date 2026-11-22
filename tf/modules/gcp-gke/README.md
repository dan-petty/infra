# gcp-gke

A regional GKE cluster with one autoscaled node pool, in its own VPC network with one subnet and
secondary ranges for the Pods and the Services. The module is a thin wrapper of two maintained
modules. It has no resource of its own.

| Module | Version | License |
| --- | --- | --- |
| [terraform-google-modules/network/google](https://github.com/terraform-google-modules/terraform-google-network) | 18.3.1 | Apache-2.0 |
| [terraform-google-modules/kubernetes-engine/google](https://github.com/terraform-google-modules/terraform-google-kubernetes-engine) | 47.0.0 | Apache-2.0 |

`main.tf` pins each module at one exact version, and Renovate updates the pins.

## Consumers

- devops-cli `devops tf deploy-cloud -p gcp`, through the example `tf/examples/gcp`
  (dan-petty/devops-cli#6679 moves the command to this module).
- Each other root module that needs a GKE cluster.

```hcl
module "gcp_gke" {
  source = "git::https://github.com/dan-petty/infra.git//tf/modules/gcp-gke?ref=vX.Y.Z"

  project_id                      = "example-project"
  region                          = "us-central1"
  cluster_name                    = "example-gke"
  network_name                    = "example-vpc"
  subnet_cidr                     = "192.0.2.0/25"
  pods_cidr                       = "198.51.100.0/24"
  services_cidr                   = "192.0.2.128/25"
  api_server_authorized_ip_ranges = ["203.0.113.0/24"]
}
```

The root module configures the `google` provider and pins its version. The modules also need the
`google-beta`, `kubernetes` and `random` providers, and the root module gets them with its lock
file.

## Inputs

The inputs are the inputs of the devops-cli stub `tf/gcp`, with two changes:

- The stub had the input `zone`, but no resource used it. The module has no `zone` input.
- The module has the input `api_server_authorized_ip_ranges`, as the module `azure-aks` has.

The module holds no value of one environment, so the project, the region, the names, the network
and the authorized ranges have no default.

| Input | Default | Use in the modules |
| --- | --- | --- |
| `project_id` | none | `project_id` of each module, and the Workload Identity pool `<project_id>.svc.id.goog`. |
| `region` | none | `region` of the regional cluster and of its subnet. |
| `cluster_name` | none | `name` of the cluster. The subnet and the node pool get the names `<cluster_name>-subnet` and `<cluster_name>-node-pool`. |
| `network_name` | none | `network_name` of the VPC network. |
| `subnet_cidr` | none | The primary range of the subnet. |
| `pods_cidr` | none | The secondary range `k8s-pod-range` of the Pods. |
| `services_cidr` | none | The secondary range `k8s-service-range` of the Services. |
| `api_server_authorized_ip_ranges` | none, at least one range | `master_authorized_networks` of the cluster. |
| `machine_type` | `"e2-standard-4"` | `machine_type` of the node pool. |
| `node_count` | `3` | `initial_node_count` of the node pool, in each zone. |
| `min_node_count` | `2` | `min_count` of the autoscaler, in each zone. |
| `max_node_count` | `5` | `max_count` of the autoscaler, in each zone. |
| `deletion_protection` | `true` | `deletion_protection` of the cluster. |
| `labels` | `{}` | The labels of the cluster and of each node. |

## Outputs

`project_id`, `cluster_name`, `cluster_endpoint` and `kubeconfig_command`, as in the devops-cli
stub. The GKE module marks the endpoint as sensitive, so `cluster_endpoint` is sensitive.

## Behavior

- The GKE module removes the default node pool and makes the node pool of the module.
- The GKE module makes a service account for the nodes with the roles of logging and monitoring,
  turns on Workload Identity, and gives the nodes the GKE metadata server (`GKE_METADATA`), as in
  the stub. `tf/.trivyignore.yaml` holds the judgment of the false trivy finding GCP-0057.
- Only `api_server_authorized_ip_ranges` can connect to the API server (trivy GCP-0061).
