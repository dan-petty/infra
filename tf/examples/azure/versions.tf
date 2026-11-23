# The Azure Verified Modules of tf/modules/azure-aks need OpenTofu 1.11 or later.
terraform {
  required_version = ">= 1.17.2"

  required_providers {
    azapi = {
      # The source is in lower case, as in .terraform.lock.hcl. Renovate compares the two names
      # with case, and with "Azure/azapi" it does not update the lock file.
      source  = "azure/azapi"
      version = "2.14.0"
    }
  }
}
