module "application_configuration" {
  source = "./vendor/modules/aks//aks/application_configuration"

  namespace              = var.namespace
  environment            = var.environment
  azure_resource_prefix  = var.azure_resource_prefix
  service_short          = var.service_short
  config_short           = var.config_short
  secret_key_vault_short = "app"

  is_rails_application = true

  config_variables = merge(
    local.app_env_values,
    {
      ENVIRONMENT_NAME    = var.environment
      PGSSLMODE           = local.postgres_ssl_mode
      CANONICAL_HOSTNAME  = local.canonical_hostname
      BIGQUERY_DATASET    = var.dataset_name
      BIGQUERY_PROJECT_ID = "claim-additional-payments"
      BIGQUERY_TABLE_NAME = "events"
  })
  secret_variables = {
    DATABASE_URL        = module.postgres.url
    HEARTBEAT_CHECK_URL = var.enable_monitoring ? module.statuscake[0].heartbeat_check_urls[local.heartbeat_check_name] : null
    GOOGLE_CLOUD_CREDENTIALS = var.enable_dfe_analytics_federated_auth ? module.dfe_analytics[0].google_cloud_credentials : null
  }
}

module "web_application" {
  source = "./vendor/modules/aks//aks/application"

  name   = "web"
  is_web = true

  namespace    = var.namespace
  environment  = var.environment
  service_name = var.service_name

  cluster_configuration_map  = module.cluster_data.configuration_map
  kubernetes_config_map_name = module.application_configuration.kubernetes_config_map_name
  kubernetes_secret_name     = module.application_configuration.kubernetes_secret_name

  docker_image = var.docker_image
  command      = var.startup_command

  replicas   = var.web_replicas
  max_memory = var.web_memory


  enable_logit = var.enable_logit
}

module "worker_application" {
  source = "./vendor/modules/aks//aks/application"

  name   = "worker"
  is_web = false

  namespace    = var.namespace
  environment  = var.environment
  service_name = var.service_name

  cluster_configuration_map  = module.cluster_data.configuration_map
  kubernetes_config_map_name = module.application_configuration.kubernetes_config_map_name
  kubernetes_secret_name     = module.application_configuration.kubernetes_secret_name

  docker_image = var.docker_image
  command      = var.worker_command

  replicas   = var.worker_replicas
  max_memory = var.worker_memory

  enable_logit = var.enable_logit
  enable_gcp_wif = true
}
