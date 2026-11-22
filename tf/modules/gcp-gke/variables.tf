# The inputs of the devops-cli stub tf/gcp, with no value of one environment. The consumer gives
# the project, the region, the names and the network of the cluster.
variable "project_id" {
  description = "The ID of the Google Cloud project of the cluster."
  type        = string
}

variable "region" {
  description = "The region of the regional cluster and of its subnet."
  type        = string
}

variable "cluster_name" {
  description = "The name of the GKE cluster. The subnet and the node pool get names that start with it."
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
  description = "The CIDR blocks that can connect to the API server of the cluster (master authorized networks). The input has no default, so the repository holds no address of an operator."
  type        = list(string)

  validation {
    condition     = length(var.api_server_authorized_ip_ranges) > 0
    error_message = "api_server_authorized_ip_ranges must have at least one CIDR block: with no range, each address can connect to the API server."
  }
}

variable "machine_type" {
  description = "The Compute Engine machine type of the node pool."
  type        = string
  default     = "e2-standard-4"
}

variable "node_count" {
  description = "The number of nodes in each zone that the node pool starts with."
  type        = number
  default     = 3
}

variable "min_node_count" {
  description = "The minimum number of nodes in each zone of the autoscaler."
  type        = number
  default     = 2
}

variable "max_node_count" {
  description = "The maximum number of nodes in each zone of the autoscaler."
  type        = number
  default     = 5
}

variable "deletion_protection" {
  description = "True stops tofu destroy and each other deletion of the cluster."
  type        = bool
  default     = true
}

variable "labels" {
  description = "The labels of the cluster and of its nodes."
  type        = map(string)
  default     = {}
}
