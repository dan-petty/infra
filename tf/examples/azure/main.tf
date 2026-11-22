# The example of the module tf/modules/azure-aks: an AKS cluster in its own resource group and
# virtual network. CI runs tofu init -backend=false and tofu validate in this folder.
# azure.tfvars.example holds the values of a test. The azapi provider reads the subscription and
# the credentials from the environment of the consumer, such as the Azure CLI login.
provider "azapi" {}

module "azure_aks" {
  source = "../../modules/azure-aks"

  resource_group_name             = var.resource_group_name
  location                        = var.location
  cluster_name                    = var.cluster_name
  dns_prefix                      = var.dns_prefix
  kubernetes_version              = var.kubernetes_version
  node_vm_size                    = var.node_vm_size
  node_count                      = var.node_count
  min_node_count                  = var.min_node_count
  max_node_count                  = var.max_node_count
  vnet_address_space              = var.vnet_address_space
  subnet_address_prefix           = var.subnet_address_prefix
  api_server_authorized_ip_ranges = var.api_server_authorized_ip_ranges
  tags                            = var.tags
}
