# The inputs of tf/modules/azure-aks. azure.tfvars.example gives a value to each one.
variable "resource_group_name" {
  description = "The name of the resource group that the module makes."
  type        = string
}

variable "location" {
  description = "The Azure region of each resource of the module."
  type        = string
}

variable "cluster_name" {
  description = "The name of the AKS cluster."
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
}

variable "node_count" {
  description = "The number of nodes that the default node pool starts with."
  type        = number
}

variable "min_node_count" {
  description = "The minimum number of nodes of the autoscaler."
  type        = number
}

variable "max_node_count" {
  description = "The maximum number of nodes of the autoscaler."
  type        = number
}

variable "vnet_address_space" {
  description = "The address space of the virtual network."
  type        = list(string)
}

variable "subnet_address_prefix" {
  description = "The address prefix of the subnet of the nodes and the pods."
  type        = string
}

variable "api_server_authorized_ip_ranges" {
  description = "The CIDR blocks that can connect to the API server of the cluster."
  type        = list(string)
}

variable "tags" {
  description = "The tags of each Azure resource of the module."
  type        = map(string)
}
