terraform {

  required_version = "= 1.8.4"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.104.2"
    }
  }
  backend "azurerm" {
    container_name = "terraform-state"
  }
}

provider "azurerm" {
  features {}

  skip_provider_registration = true
}
