# The example of the module tf/modules/aws-eks: an EKS cluster in its own VPC. CI runs tofu init
# -backend=false and tofu validate in this folder. aws.tfvars.example holds the values of a test.
# The AWS provider reads its credentials from the environment of the consumer.
provider "aws" {
  region = var.aws_region
}

module "aws_eks" {
  source = "../../modules/aws-eks"

  aws_region            = var.aws_region
  cluster_name          = var.cluster_name
  kubernetes_version    = var.kubernetes_version
  vpc_cidr              = var.vpc_cidr
  availability_zones    = var.availability_zones
  node_instance_types   = var.node_instance_types
  node_desired_capacity = var.node_desired_capacity
  node_min_capacity     = var.node_min_capacity
  node_max_capacity     = var.node_max_capacity
  tags                  = var.tags
}
