# OpenTofu modules

Each folder `tf/modules/<module>/` is one OpenTofu module. A module holds no value of one
environment and no state: the consumer gives each value as a variable. Each module has an example
in `tf/examples/`.

The OpenTofu job of CI runs `tofu fmt -check` and tflint (`.tflint.hcl`, all rules of the
terraform ruleset) on each module, and `trivy config` on each module through its example
(README.md, "Checks").

A module that wraps a registry module pins it at one exact version in `main.tf`, and Renovate
updates the pin. A module declares a provider only for a resource of its own, and then gives a
lower bound only: the root module of the consumer pins the exact version of each provider, so a
release of infra and a pin of the consumer cannot ask for two versions of one provider.

The README of each module names its consumers.

| Module | Content | Example | Consumers |
| --- | --- | --- | --- |
| `example` | One output from one variable: the fixture of the checks. | `tf/examples/example` | None. |
| `aws-eks` | An EKS cluster in its own VPC, on terraform-aws-modules/vpc and eks ([README](aws-eks/README.md)). | `tf/examples/aws` | devops-cli `devops tf deploy-cloud -p aws` (dan-petty/devops-cli#6679). |
| `azure-aks` | An AKS cluster in its own resource group and virtual network, on the Azure Verified Modules ([README](azure-aks/README.md)). | `tf/examples/azure` | devops-cli `devops tf deploy-cloud -p azure` (dan-petty/devops-cli#6679). |
| `gcp-gke` | A regional GKE cluster in its own VPC network, on terraform-google-modules/network and kubernetes-engine ([README](gcp-gke/README.md)). | `tf/examples/gcp` | devops-cli `devops tf deploy-cloud -p gcp` (dan-petty/devops-cli#6679). |

A consumer pins a module at a release tag of infra:

```hcl
module "<name>" {
  source = "git::https://github.com/dan-petty/infra.git//tf/modules/<module>?ref=vX.Y.Z"
}
```
