resource "azurerm_resource_group" "example" {
  name     = format("%s-%s", var.app_rg_name, "pr-resource-group")
  location = var.rg_location
}
