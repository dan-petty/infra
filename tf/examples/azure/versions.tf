# The Azure Verified Modules of tf/modules/azure-aks need OpenTofu 1.11 or later.
terraform {
  required_version = ">= 1.11"

  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = "2.14.0"
    }
  }
}
