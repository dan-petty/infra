# The Azure Verified Modules need OpenTofu 1.11 or later and azapi 2.12 or a later 2.x release. The
# module gives a lower bound only; the root module of the consumer pins the exact provider version
# (tf/examples/azure).
terraform {
  required_version = ">= 1.11"

  required_providers {
    azapi = {
      source  = "azure/azapi"
      version = ">= 2.12, < 3.0"
    }
  }
}
