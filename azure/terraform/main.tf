#set common tags
module "env_vars" {
  source            = "./modules/env_vars"
  input_environment = var.input_environment
}

#container
module "container" {
  source                = "./modules/container"
  app_rg_name           = format("%s-%s", module.env_vars.rg_prefix, "app")
  projcore_network_prof = data.terraform_remote_state.infra.outputs.projcore_network_prof
  container_version     = var.input_container_version
  rg_prefix             = module.env_vars.rg_prefix
  rg_location           = var.input_region
  common_tags           = module.env_vars.common_tags
}

module "app_service" {
  source                  = "./modules/app_service"
  app_rg_name             = format("%s-%s", module.env_vars.rg_prefix, "app")
  app_asp_id              = data.terraform_remote_state.infra.outputs.app_asp_id
  input_container_version = var.input_container_version
  rg_prefix               = module.env_vars.rg_prefix
  rg_location             = var.input_region
  common_tags             = module.env_vars.common_tags

}
