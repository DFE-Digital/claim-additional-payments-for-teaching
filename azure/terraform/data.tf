data "azurerm_subscription" "current" {

}

data "terraform_remote_state" "infra" {
  backend = "azurerm"
  config = {
    resource_group_name  = format("%s-%s", local.rg_prefix, "tfbackend")
    storage_account_name = format("%s%s", local.rg_prefix, "tfbackendsa")
    container_name       = local.tf_sa_container
    key                  = "terraform.tfstate"
    subscription_id      = data.azurerm_subscription.current.subscription_id
    tenant_id            = data.azurerm_subscription.current.tenant_id
  }
}
