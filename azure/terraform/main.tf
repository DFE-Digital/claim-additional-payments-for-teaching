module "container" {
  # Only impacts review apps: makes sure the app is deleted before the database
  depends_on = [
    azurerm_postgresql_database.app
  ]

  source                = "./modules/container"
  app_rg_name           = format("%s-%s", var.rg_prefix, "app")
  container_version     = var.input_container_version
  rg_prefix             = var.rg_prefix
  rg_location           = local.input_region
  common_tags           = local.tags
  db_host                 = data.azurerm_postgresql_server.app.fqdn
  db_admin_username       = data.azurerm_postgresql_server.app.administrator_login
  db_name                 = local.db_name
  environment             = var.environment
  canonical_hostname      = var.canonical_hostname
  bypass_dfe_sign_in      = var.bypass_dfe_sign_in
  suppress_dfe_analytics_init = var.suppress_dfe_analytics_init
}

module "app_service" {
  # Only impacts review apps: makes sure the app is deleted before the database
  depends_on = [
    azurerm_postgresql_database.app
  ]

  source                  = "./modules/app_service"
  app_rg_name             = local.app_rg_name
  input_container_version = var.input_container_version
  rg_prefix               = var.rg_prefix
  rg_location             = local.input_region
  common_tags             = local.tags
  db_host                 = data.azurerm_postgresql_server.app.fqdn
  db_admin_username       = data.azurerm_postgresql_server.app.administrator_login
  db_name                 = local.db_name
  environment             = var.environment
  canonical_hostname      = var.canonical_hostname
  ssl_hostnames           = var.ssl_hostnames
  bypass_dfe_sign_in      = var.bypass_dfe_sign_in
  suppress_dfe_analytics_init = var.suppress_dfe_analytics_init
  enable_basic_auth       = var.enable_basic_auth
  keyvault_cert_name      = var.keyvault_cert_name
}
