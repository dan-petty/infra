# azure-aks

An AKS cluster with one autoscaled system node pool, in its own resource group and virtual
network. The module is a thin wrapper of three Azure Verified Modules, which use the azapi
provider.

| Module | Version | License |
| --- | --- | --- |
| [Azure/avm-res-resources-resourcegroup/azurerm](https://github.com/Azure/terraform-azurerm-avm-res-resources-resourcegroup) | 0.5.0 | MIT |
| [Azure/avm-res-network-virtualnetwork/azurerm](https://github.com/Azure/terraform-azurerm-avm-res-network-virtualnetwork) | 0.23.0 | MIT |
| [Azure/avm-res-containerservice-managedcluster/azurerm](https://github.com/Azure/terraform-azurerm-avm-res-containerservice-managedcluster) | 0.9.0 | MIT |

`main.tf` pins each module at one exact version, and Renovate updates the pins. The module has one
resource of its own: the user-assigned identity of the control plane. The Azure Verified Module for
an identity uses the azurerm provider, so the module writes this one `azapi_resource`, as the
examples of the AKS module do.

## Consumers

- devops-cli `devops tf deploy-cloud -p azure`, through the example `tf/examples/azure`
  (dan-petty/devops-cli#6679 moves the command to this module).
- Each other root module that needs an AKS cluster.

```hcl
module "azure_aks" {
  source = "git::https://github.com/dan-petty/infra.git//tf/modules/azure-aks?ref=vX.Y.Z"

  resource_group_name             = "rg-example-aks"
  location                        = "eastus"
  cluster_name                    = "example-aks"
  dns_prefix                      = "example-aks"
  vnet_address_space              = ["192.0.2.0/24"]
  subnet_address_prefix           = "192.0.2.0/25"
  api_server_authorized_ip_ranges = ["203.0.113.0/24"]
}
```

The root module configures the `azapi` provider and pins its version. The modules need OpenTofu
1.11 or later and azapi 2.12 or a later 2.x release.

## Inputs

The inputs are the inputs of the devops-cli stub `tf/azure`. The module holds no value of one
environment, so the names, the region, the network and the authorized ranges have no default.

| Input | Default | Use in the modules |
| --- | --- | --- |
| `resource_group_name` | none | `name` of the resource group. |
| `location` | none | `location` of each resource. |
| `cluster_name` | none | `name` of the cluster. The identity, the virtual network and the subnet get the names `<cluster_name>-identity`, `<cluster_name>-vnet` and `<cluster_name>-subnet`. |
| `dns_prefix` | none | `dns_prefix` of the cluster. |
| `kubernetes_version` | `null`: the default version of AKS | `kubernetes_version` of the cluster. |
| `node_vm_size` | `"Standard_D4s_v5"` | `vm_size` of the default node pool. |
| `node_count` | `3` | `count_of` of the default node pool. |
| `min_node_count` | `2` | `min_count` of the autoscaler. |
| `max_node_count` | `5` | `max_count` of the autoscaler. |
| `vnet_address_space` | none | `address_space` of the virtual network. |
| `subnet_address_prefix` | none | The address prefix of the subnet of the nodes and the Pods. |
| `api_server_authorized_ip_ranges` | none, at least one range | `authorized_ip_ranges` of the API server. |
| `tags` | `{}` | `tags` of each resource. |

## Outputs

`resource_group_name`, `cluster_name`, `cluster_endpoint` and `kubeconfig_command`, as in the
devops-cli stub. `cluster_endpoint` is `https://<fqdn>:443`, the host of the kubeconfig of AKS.

## Behavior

- The identity of the control plane gets the role Network Contributor on the subnet before the
  cluster starts, as in the stub.
- Only `api_server_authorized_ip_ranges` can connect to the API server (trivy AZU-0041,
  dan-petty/devops-cli#5767). The input has no default, so the repository holds no address of an
  operator.
- The cluster uses Azure CNI and a standard load balancer. The Service CIDR and the DNS address
  are the defaults of AKS, the values that the stub set.
- Each Azure Verified Module gets `enable_telemetry = false`, so no module sends usage data to
  Microsoft.
