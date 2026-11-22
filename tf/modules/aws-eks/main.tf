# An EKS cluster in its own VPC: a thin wrapper of the maintained modules
# terraform-aws-modules/vpc/aws and terraform-aws-modules/eks/aws. The wrapper maps the inputs of
# the devops-cli stub tf/aws onto the inputs of the two modules (README.md, "Inputs").
locals {
  # One public and one private subnet in each zone, as in the devops-cli stub: the public subnets
  # take the first 8 of the 16 blocks of the VPC, and the private subnets take the last 8.
  public_subnets  = [for index in range(length(var.availability_zones)) : cidrsubnet(var.vpc_cidr, 4, index)]
  private_subnets = [for index in range(length(var.availability_zones)) : cidrsubnet(var.vpc_cidr, 4, index + 8)]
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "6.8.0"

  region = var.aws_region
  name   = "${var.cluster_name}-vpc"
  cidr   = var.vpc_cidr
  azs    = var.availability_zones

  public_subnets  = local.public_subnets
  private_subnets = local.private_subnets

  # One NAT gateway gives the egress of the private subnets.
  enable_nat_gateway = true
  single_nat_gateway = true

  # The load balancer controller puts public load balancers in the public subnets, and internal
  # load balancers in the private subnets.
  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
  }
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
  }

  tags = var.tags
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "21.30.2"

  region             = var.aws_region
  name               = var.cluster_name
  kubernetes_version = var.kubernetes_version

  # The nodes and the control plane use the private subnets.
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  # The API server has a private endpoint only, as in the devops-cli stub.
  endpoint_private_access = true
  endpoint_public_access  = false

  # The identity that applies the module becomes a cluster administrator, as the stub did with the
  # default access of aws_eks_cluster. Thus the kubeconfig command of the outputs gives access.
  enable_cluster_creator_admin_permissions = true

  # The EKS module does not bootstrap the self-managed add-ons (bootstrap_self_managed_addons =
  # false), so it installs the add-ons that the stub got from EKS through the add-on API. vpc-cni
  # comes before the node group, so that the nodes become Ready.
  addons = {
    coredns    = {}
    kube-proxy = {}
    vpc-cni = {
      before_compute = true
    }
  }

  eks_managed_node_groups = {
    default = {
      instance_types = var.node_instance_types
      desired_size   = var.node_desired_capacity
      min_size       = var.node_min_capacity
      max_size       = var.node_max_capacity
    }
  }

  tags = var.tags
}
