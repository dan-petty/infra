output "resource_group_name" {
  description = "The name of the resource group."
  value       = module.resource_group.name
}

output "cluster_name" {
  description = "The name of the AKS cluster."
  value       = module.aks.name
}

output "cluster_endpoint" {
  description = "The endpoint of the Kubernetes API server."
  value       = "https://${module.aks.fqdn}:443"
}

output "kubeconfig_command" {
  description = "The Azure CLI command that adds the cluster to the local kubeconfig."
  value       = "az aks get-credentials --resource-group ${module.resource_group.name} --name ${module.aks.name} --overwrite-existing"
}
