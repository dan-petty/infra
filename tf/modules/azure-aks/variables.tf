# The inputs of the devops-cli stub tf/azure, with no value of one environment. The consumer gives
# the names, the region, the network and the authorized ranges of the cluster.
variable "resource_group_name" {
  description = "The name of the resource group that the module makes."
  type        = string
}

variable "location" {
  description = "The Azure region of each resource of the module."
  type        = string
}

variable "cluster_name" {
  description = "The name of the AKS cluster. The identity, the virtual network and the subnet get names that start with it."
  type        = string
}

variable "dns_prefix" {
  description = "The DNS prefix of the API server of the cluster."
  type        = string
}

variable "kubernetes_version" {
  description = "The Kubernetes version of the cluster, such as 1.34. Null selects the default version of AKS."
  type        = string
  default     = null
}

variable "node_vm_size" {
  description = "The VM size of the default node pool."
  type        = string
  default     = "Standard_D4s_v5"
}

variable "node_count" {
  description = "The number of nodes that the default node pool starts with."
  type        = number
  default     = 3
}

variable "min_node_count" {
  description = "The minimum number of nodes of the autoscaler."
  type        = number
  default     = 2
}

variable "max_node_count" {
  description = "The maximum number of nodes of the autoscaler."
  type        = number
  default     = 5
}

variable "vnet_address_space" {
  description = "The address space of the virtual network."
  type        = list(string)
}

variable "subnet_address_prefix" {
  description = "The address prefix of the subnet of the nodes and the pods. It must be in vnet_address_space."
  type        = string
}

variable "api_server_authorized_ip_ranges" {
  description = "The CIDR blocks that can connect to the API server of the cluster. The input has no default, so the repository holds no address of an operator."
  type        = list(string)

  validation {
    condition     = length(var.api_server_authorized_ip_ranges) > 0
    error_message = "api_server_authorized_ip_ranges must have at least one CIDR block: with no range, each address can connect to the API server."
  }
}

variable "tags" {
  description = "The tags of each Azure resource of the module."
  type        = map(string)
  default     = {}
}
