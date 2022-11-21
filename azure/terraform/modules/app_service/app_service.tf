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

data "azurerm_key_vault_certificate" "app" {
  for_each     = local.cert_set
  name         = var.keyvault_cert_name
  key_vault_id = data.azurerm_key_vault.secrets_kv.id
}

resource "azurerm_app_service_certificate" "app" {
  for_each            = local.cert_set
  name                = "${data.azurerm_key_vault.secrets_kv.name}-${var.keyvault_cert_name}"
  resource_group_name = var.app_rg_name
  location            = var.rg_location
  key_vault_secret_id = data.azurerm_key_vault_certificate.app[var.keyvault_cert_name].id

   lifecycle {
    ignore_changes = [ tags ]
  }
}

resource "azurerm_app_service_custom_hostname_binding" "app" {
  for_each            = toset(var.ssl_hostnames)
  hostname            = each.key
  app_service_name    = local.app_service_name
  resource_group_name = var.app_rg_name
}

resource "azurerm_app_service_certificate_binding" "app" {
  for_each            = toset(var.ssl_hostnames)
  hostname_binding_id = azurerm_app_service_custom_hostname_binding.app[each.key].id
  certificate_id      = azurerm_app_service_certificate.app[var.keyvault_cert_name].id
  ssl_state           = "SniEnabled"
}
