#set common tags
module "env_vars" {
  source            = "./modules/env_vars"
  input_environment = var.input_environment
}

#container
module "container" {
  source                = "./modules/container"
  app_rg_name           = format("%s-%s", var.rg_prefix, "app")
  container_version     = var.input_container_version
  rg_prefix             = var.rg_prefix
  rg_location           = var.input_region
  common_tags           = module.env_vars.common_tags
  app_name              = var.app_name
  db_host                 = data.azurerm_postgresql_server.app.fqdn
  db_admin_username       = data.azurerm_postgresql_server.app.administrator_login
  db_name                 = local.db_name
}

module "app_service" {
  source                  = "./modules/app_service"
  app_rg_name             = local.app_rg_name
  input_container_version = var.input_container_version
  rg_prefix               = var.rg_prefix
  rg_location             = var.input_region
  common_tags             = module.env_vars.common_tags
  app_name                = var.app_name
  db_host                 = data.azurerm_postgresql_server.app.fqdn
  db_admin_username       = data.azurerm_postgresql_server.app.administrator_login
  db_name                 = local.db_name
}

###Run if ENV eq PRNumber

# module "azure-resource-group" {
#     source = "./modules/azure-resource-group"
#     name = "ratest"
#     location = "west europe"
#    }

# module "claims-db" {
#     source = "./modules/databses"
#     name = "ratest"
#     location = "west europe"
#    }

# module "redis_cache" {
#     source = "./modules/redis_cache"
#     name = "ratest"
#     location = "west europe"
#    }
