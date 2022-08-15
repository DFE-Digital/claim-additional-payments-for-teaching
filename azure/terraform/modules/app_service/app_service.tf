resource "azurerm_linux_web_app" "app_as" {
  name                = local.app_service_name
  resource_group_name = var.app_rg_name
  location            = var.rg_location
  service_plan_id     = data.azurerm_service_plan.app.id

  client_affinity_enabled = true
  https_only              = true

  site_config {}

  app_settings = local.environment_variables

  tags = var.common_tags
}
