provider "azurerm" {
  #alias = "main"
  # Whilst version is optional, we /strongly recommend/ using it to pin the version of the Provider being used

  #source.com
  subscription_id = local.sub_id
  tenant_id       = "9c7d9dd3-840c-4b3f-818e-552865082e16"

  features {}

}

provider "azuread" {
}

provider "random" {
}

terraform {
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
    random = {
      source  = "hashicorp/random"
      version = "=3.1.0"
    }
  }
}

