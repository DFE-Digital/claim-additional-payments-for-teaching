terraform {
  required_version = "= 1.8.4"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.116.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.32.0"
    }
    statuscake = {
      source  = "StatusCakeDev/statuscake"
      version = "2.2.2"
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

provider "kubernetes" {
  host                   = module.cluster_data.kubernetes_host
  cluster_ca_certificate = module.cluster_data.kubernetes_cluster_ca_certificate

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "kubelogin"
    args        = ["get-token", "--server-id","6dae42f8-4368-4678-94ff-3960e28e3630"]
  }
}


provider "statuscake" {
  api_token = module.infrastructure_secrets.map.STATUSCAKE-API-TOKEN
}
