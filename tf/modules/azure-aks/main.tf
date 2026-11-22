# An AKS cluster in its own resource group and virtual network: a thin wrapper of the Azure Verified
# Modules for the resource group, the virtual network and the AKS managed cluster. The wrapper maps
# the inputs of the devops-cli stub tf/azure onto the inputs of the modules (README.md, "Inputs").
# Each module gets enable_telemetry = false, so no module sends usage data to Microsoft.
module "resource_group" {
  source  = "Azure/avm-res-resources-resourcegroup/azurerm"
  version = "0.5.0"

  name             = var.resource_group_name
  location         = var.location
  tags             = var.tags
  enable_telemetry = false
}

# The user-assigned identity of the control plane. It gets the role Network Contributor on the
# subnet before the cluster starts, as in the devops-cli stub. The Azure Verified Module for an
# identity uses the azurerm provider, so the wrapper writes this one azapi resource, as the
# examples of the AKS module do.
resource "azapi_resource" "identity" {
  type                   = "Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31"
  name                   = "${var.cluster_name}-identity"
  parent_id              = module.resource_group.resource_id
  location               = var.location
  tags                   = var.tags
  response_export_values = ["properties.principalId"]
}

module "virtual_network" {
  source  = "Azure/avm-res-network-virtualnetwork/azurerm"
  version = "0.23.0"

  name             = "${var.cluster_name}-vnet"
  parent_id        = module.resource_group.resource_id
  location         = var.location
  address_space    = toset(var.vnet_address_space)
  tags             = var.tags
  enable_telemetry = false

  subnets = {
    aks = {
      name             = "${var.cluster_name}-subnet"
      address_prefixes = [var.subnet_address_prefix]
      role_assignments = {
        network_contributor = {
          role_definition_id_or_name = "Network Contributor"
          principal_id               = azapi_resource.identity.output.properties.principalId
          principal_type             = "ServicePrincipal"
        }
      }
    }
  }
}

module "aks" {
  source  = "Azure/avm-res-containerservice-managedcluster/azurerm"
  version = "0.9.0"

  name               = var.cluster_name
  parent_id          = module.resource_group.resource_id
  location           = var.location
  dns_prefix         = var.dns_prefix
  kubernetes_version = var.kubernetes_version
  tags               = var.tags
  enable_telemetry   = false

  managed_identities = {
    user_assigned_resource_ids = [azapi_resource.identity.id]
  }

  default_agent_pool = {
    vm_size             = var.node_vm_size
    count_of            = var.node_count
    enable_auto_scaling = true
    min_count           = var.min_node_count
    max_count           = var.max_node_count
    vnet_subnet_id      = module.virtual_network.subnets["aks"].resource_id
    tags                = var.tags
  }

  # Only these ranges can connect to the API server (Trivy AZU-0041, devops-cli#5767).
  api_server_access_profile = {
    authorized_ip_ranges = var.api_server_authorized_ip_ranges
  }

  # Azure CNI and a standard load balancer, as in the devops-cli stub. The Service CIDR and the DNS
  # address are the defaults of AKS.
  network_profile = {
    network_plugin    = "azure"
    load_balancer_sku = "standard"
  }

  # The role assignment of the identity on the subnet must exist before the cluster starts.
  depends_on = [module.virtual_network]
}
