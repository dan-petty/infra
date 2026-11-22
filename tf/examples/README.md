# OpenTofu examples

Each folder of `tf/examples/` is a root module that calls one module of `tf/modules/` with the
values of a test: `example.com` and RFC 5737 addresses. An example has no backend and no state.

| Example | Module | Values |
| --- | --- | --- |
| `example` | `example` | In `main.tf`. |
| `aws` | `aws-eks` | In `aws.tfvars.example`. |
| `azure` | `azure-aks` | In `azure.tfvars.example`. |
| `gcp` | `gcp-gke` | In `gcp.tfvars.example`. |

The examples `aws`, `azure` and `gcp` configure the provider of their cloud, pin its exact version
in `versions.tf`, and pin each provider of the modules in `.terraform.lock.hcl`. Each one declares
the inputs of its module as variables, and `<folder>.tfvars.example` gives a value to each
variable. A consumer runs `tofu init` and `tofu plan` in the example with a copy of that file, as
devops-cli `devops tf deploy-cloud -p <folder>` will do (dan-petty/devops-cli#6679). The provider
reads the credentials from the environment of the consumer.

The OpenTofu job of CI runs `trivy config` with the values of `<folder>.tfvars.example`,
`tofu init -backend=false` and `tofu validate` in each example, and `tofu fmt -check` and tflint
on it (README.md, "Checks"). CI makes no plan and uses no cloud credentials.
