provider "azurerm" {
  features {}
}

provider "azuread" {
}

terraform {
  required_version = "= 1.2.4"

  backend "azurerm" {
    key = "terraform.tfstate"
  }

  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = "=1.4.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=2.49.0"
    }
  }
}
