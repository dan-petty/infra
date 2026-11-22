output "project_id" {
  description = "The ID of the Google Cloud project."
  value       = module.gcp_gke.project_id
}

output "cluster_name" {
  description = "The name of the GKE cluster."
  value       = module.gcp_gke.cluster_name
}

output "cluster_endpoint" {
  description = "The endpoint of the Kubernetes API server."
  value       = module.gcp_gke.cluster_endpoint
  sensitive   = true
}

output "kubeconfig_command" {
  description = "The gcloud command that adds the cluster to the local kubeconfig."
  value       = module.gcp_gke.kubeconfig_command
}
