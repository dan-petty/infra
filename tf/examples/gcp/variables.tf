# The inputs of tf/modules/gcp-gke. gcp.tfvars.example gives a value to each one.
variable "project_id" {
  description = "The ID of the Google Cloud project of the cluster and of the provider."
  type        = string
}

variable "region" {
  description = "The region of the regional cluster and of its subnet."
  type        = string
}

variable "cluster_name" {
  description = "The name of the GKE cluster."
  type        = string
}

variable "network_name" {
  description = "The name of the VPC network that the module makes."
  type        = string
}

variable "subnet_cidr" {
  description = "The primary CIDR range of the subnet of the nodes."
  type        = string
}

variable "pods_cidr" {
  description = "The secondary CIDR range of the Pods."
  type        = string
}

variable "services_cidr" {
  description = "The secondary CIDR range of the Services."
  type        = string
}

variable "api_server_authorized_ip_ranges" {
  description = "The CIDR blocks that can connect to the API server of the cluster."
  type        = list(string)
}

variable "machine_type" {
  description = "The Compute Engine machine type of the node pool."
  type        = string
}

variable "node_count" {
  description = "The number of nodes in each zone that the node pool starts with."
  type        = number
}

variable "min_node_count" {
  description = "The minimum number of nodes in each zone of the autoscaler."
  type        = number
}

variable "max_node_count" {
  description = "The maximum number of nodes in each zone of the autoscaler."
  type        = number
}

variable "deletion_protection" {
  description = "True stops tofu destroy and each other deletion of the cluster."
  type        = bool
}

variable "labels" {
  description = "The labels of the cluster and of its nodes."
  type        = map(string)
}
