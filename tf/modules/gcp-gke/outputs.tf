output "project_id" {
  description = "The ID of the Google Cloud project."
  value       = var.project_id
}

output "cluster_name" {
  description = "The name of the GKE cluster."
  value       = module.gke.name
}

output "cluster_endpoint" {
  description = "The endpoint of the Kubernetes API server. The GKE module marks it as sensitive."
  value       = module.gke.endpoint
  sensitive   = true
}

output "kubeconfig_command" {
  description = "The gcloud command that adds the cluster to the local kubeconfig."
  value       = "gcloud container clusters get-credentials ${module.gke.name} --region ${var.region} --project ${var.project_id}"
}
