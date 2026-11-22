output "resource_group_name" {
  description = "The name of the resource group."
  value       = module.azure_aks.resource_group_name
}

output "cluster_name" {
  description = "The name of the AKS cluster."
  value       = module.azure_aks.cluster_name
}

output "cluster_endpoint" {
  description = "The endpoint of the Kubernetes API server."
  value       = module.azure_aks.cluster_endpoint
}

output "kubeconfig_command" {
  description = "The Azure CLI command that adds the cluster to the local kubeconfig."
  value       = module.azure_aks.kubeconfig_command
}
