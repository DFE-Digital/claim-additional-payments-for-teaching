data "azurerm_subscription" "current" {

}

data "terraform_remote_state" "infra" {
  backend = "azurerm"
  config = {
    resource_group_name  = "s118d01-tfbackend"
    storage_account_name = "s118d01tfbackendsa"
    container_name       = "s118d01devtfstate"
    key                  = "terraform.tfstate"
    subscription_id      = data.azurerm_subscription.current.subscription_id
    tenant_id            = data.azurerm_subscription.current.tenant_id
  }
}