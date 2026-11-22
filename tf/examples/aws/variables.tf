# The inputs of tf/modules/aws-eks. aws.tfvars.example gives a value to each one.
variable "aws_region" {
  description = "The AWS region of the cluster and of the provider."
  type        = string
}

variable "cluster_name" {
  description = "The name of the EKS cluster."
  type        = string
}

variable "kubernetes_version" {
  description = "The Kubernetes version of the control plane, such as 1.34. Null selects the default version of EKS."
  type        = string
  default     = null
}

variable "vpc_cidr" {
  description = "The CIDR block of the VPC of the cluster."
  type        = string
}

variable "availability_zones" {
  description = "The availability zones of the subnets: one public and one private subnet in each zone."
  type        = list(string)
}

variable "node_instance_types" {
  description = "The EC2 instance types of the managed node group."
  type        = list(string)
}

variable "node_desired_capacity" {
  description = "The number of nodes that the managed node group starts with."
  type        = number
}

variable "node_min_capacity" {
  description = "The minimum number of nodes of the managed node group."
  type        = number
}

variable "node_max_capacity" {
  description = "The maximum number of nodes of the managed node group."
  type        = number
}

variable "tags" {
  description = "The tags of each AWS resource of the module."
  type        = map(string)
}
