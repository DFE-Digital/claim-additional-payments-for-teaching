resource "azurerm_resource_group" "example" {
  name     = "RAPPTEST"
  location = "West Europe"
}

tags = merge({
    },
    var.common_tags
  )
