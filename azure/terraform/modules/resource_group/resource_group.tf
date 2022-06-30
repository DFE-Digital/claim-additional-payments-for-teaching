resource "azurerm_resource_group" "example" {
  name     = format("%s-%s", var.app_rg_name, "worker-aci")
  location = "West Europe"
}
