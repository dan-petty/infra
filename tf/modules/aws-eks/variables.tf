# The inputs of the devops-cli stub tf/aws, with no value of one environment. The consumer gives
# the name, the region and the network of the cluster.
variable "aws_region" {
  description = "The AWS region of each resource of the module."
  type        = string
}

variable "cluster_name" {
  description = "The name of the EKS cluster. The VPC gets the name <cluster_name>-vpc."
  type        = string
}

variable "kubernetes_version" {
  description = "The Kubernetes version of the control plane, such as 1.34. Null selects the default version of EKS."
  type        = string
  default     = null
}

variable "vpc_cidr" {
  description = "The CIDR block of the VPC of the cluster. The module divides it into 16 subnets of equal size."
  type        = string

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "vpc_cidr must be an IPv4 CIDR block, such as 192.0.2.0/24."
  }
}

variable "availability_zones" {
  description = "The availability zones of the subnets: one public and one private subnet in each zone."
  type        = list(string)

  validation {
    condition     = length(var.availability_zones) >= 2 && length(var.availability_zones) <= 8
    error_message = "availability_zones must have 2 to 8 zones: EKS needs subnets in 2 zones, and the VPC has 8 blocks for each subnet kind."
  }
}

variable "node_instance_types" {
  description = "The EC2 instance types of the managed node group."
  type        = list(string)
  default     = ["t3.xlarge"]
}

variable "node_desired_capacity" {
  description = "The number of nodes that the managed node group starts with."
  type        = number
  default     = 3
}

variable "node_min_capacity" {
  description = "The minimum number of nodes of the managed node group."
  type        = number
  default     = 2
}

variable "node_max_capacity" {
  description = "The maximum number of nodes of the managed node group."
  type        = number
  default     = 5
}

variable "tags" {
  description = "The tags of each AWS resource of the module."
  type        = map(string)
  default     = {}
}
