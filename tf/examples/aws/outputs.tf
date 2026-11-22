output "cluster_name" {
  description = "The name of the EKS cluster."
  value       = module.aws_eks.cluster_name
}

output "cluster_endpoint" {
  description = "The endpoint of the Kubernetes API server."
  value       = module.aws_eks.cluster_endpoint
}

output "cluster_arn" {
  description = "The ARN of the EKS cluster."
  value       = module.aws_eks.cluster_arn
}

output "cluster_certificate_authority_data" {
  description = "The base64 certificate data of the cluster CA."
  value       = module.aws_eks.cluster_certificate_authority_data
  sensitive   = true
}

output "vpc_id" {
  description = "The ID of the VPC of the cluster."
  value       = module.aws_eks.vpc_id
}

output "kubeconfig_command" {
  description = "The AWS CLI command that adds the cluster to the local kubeconfig."
  value       = module.aws_eks.kubeconfig_command
}
