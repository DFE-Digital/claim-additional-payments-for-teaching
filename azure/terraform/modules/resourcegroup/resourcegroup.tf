resource "azurerm_resource_group" "example" {
  name     = format("%s-%s", var.rg_prefix, "pr-resource-group")
  location = var.rg_location
}
