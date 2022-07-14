# variable "client_secret" {
# }

# We strongly recommend using the required_providers block to set the
# Azure Provider source and version being used
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.0"
    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}

  subscription_id = "8655985a-2f87-44d7-a541-0be9a8c2779d"
  client_id       = "699d030d-46e4-4abb-a4f4-b114c8aed813"
  client_secret   = "b5b563e8-f505-4917-a53d-99c3be4c2359"
  tenant_id       = "9c7d9dd3-840c-4b3f-818e-552865082e16"
}
