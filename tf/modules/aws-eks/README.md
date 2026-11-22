# aws-eks

An EKS cluster with one managed node group, in its own VPC with a public and a private subnet in
each availability zone and one NAT gateway. The module is a thin wrapper of two maintained
modules. It has no resource of its own.

| Module | Version | License |
| --- | --- | --- |
| [terraform-aws-modules/vpc/aws](https://github.com/terraform-aws-modules/terraform-aws-vpc) | 6.8.0 | Apache-2.0 |
| [terraform-aws-modules/eks/aws](https://github.com/terraform-aws-modules/terraform-aws-eks) | 21.30.2 | Apache-2.0 |

`main.tf` pins each module at one exact version, and Renovate updates the pins.

## Consumers

- devops-cli `devops tf deploy-cloud -p aws`, through the example `tf/examples/aws`
  (dan-petty/devops-cli#6679 moves the command to this module).
- Each other root module that needs an EKS cluster.

```hcl
module "aws_eks" {
  source = "git::https://github.com/dan-petty/infra.git//tf/modules/aws-eks?ref=vX.Y.Z"

  aws_region         = "us-west-2"
  cluster_name       = "example-eks"
  vpc_cidr           = "192.0.2.0/24"
  availability_zones = ["us-west-2a", "us-west-2b", "us-west-2c"]
}
```

The root module configures the `aws` provider and pins its version. The module needs the AWS
provider 6.59 or later, the version that the EKS module needs.

## Inputs

The inputs are the inputs of the devops-cli stub `tf/aws`. The module holds no value of one
environment, so the name, the region and the network have no default.

| Input | Default | Use in the modules |
| --- | --- | --- |
| `aws_region` | none | `region` of the VPC and the EKS module, and the region of `kubeconfig_command`. |
| `cluster_name` | none | `name` of the EKS module. The VPC gets the name `<cluster_name>-vpc`. |
| `kubernetes_version` | `null`: the default version of EKS | `kubernetes_version` of the EKS module. |
| `vpc_cidr` | none | `cidr` of the VPC. The module divides it into 16 blocks: the public subnets get blocks 0 to 7, and the private subnets get blocks 8 to 15. |
| `availability_zones` | none | `azs` of the VPC: one public and one private subnet in each zone, 2 to 8 zones. |
| `node_instance_types` | `["t3.xlarge"]` | `instance_types` of the node group `default`. |
| `node_desired_capacity` | `3` | `desired_size` of the node group. |
| `node_min_capacity` | `2` | `min_size` of the node group. |
| `node_max_capacity` | `5` | `max_size` of the node group. |
| `tags` | `{}` | `tags` of each resource. |

## Outputs

`cluster_name`, `cluster_endpoint`, `cluster_arn`, `cluster_certificate_authority_data`
(sensitive), `vpc_id` and `kubeconfig_command`, as in the devops-cli stub.

## Behavior

- The nodes and the control plane use the private subnets. The public subnets get the tag
  `kubernetes.io/role/elb`, and the private subnets get the tag `kubernetes.io/role/internal-elb`.
- The API server has a private endpoint only, as in the stub. Thus `kubeconfig_command` gives
  access only from the VPC or from a network that connects to it.
- The identity that applies the module becomes a cluster administrator
  (`enable_cluster_creator_admin_permissions`), as the stub did with the default access of EKS.
- The EKS module adds a KMS key for the encryption of the Secrets, and a CloudWatch log group for
  the audit, API and authenticator logs of the control plane.
- The node security group of the EKS module lets the nodes connect to each address, through the
  NAT gateway. `tf/.trivyignore.yaml` holds the judgment of the trivy finding AWS-0104.
