resource "azurerm_resource_group" "example" {
  name     = "s118d01-ra-app"
  location = "West Europe"
}

  tags = merge({
    },
    var.common_tags
  )
