data "azurerm_postgresql_server" "app" {
  name = format("%s-%s", local.app_rg_name, "db11")
  resource_group_name = local.app_rg_name
}

resource "azurerm_postgresql_database" "app" {
  for_each = toset(local.create_db_list)

  name                = each.value
  resource_group_name = local.app_rg_name
  server_name         = data.azurerm_postgresql_server.app.name
  charset             = "UTF8"
  collation           = "English_United States.1252"
}
