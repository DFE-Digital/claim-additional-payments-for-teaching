module "airbyte" {
  source = "./vendor/modules/aks//aks/airbyte"

  count = var.airbyte_enabled ? 1 : 0

  environment           = var.environment
  azure_resource_prefix = var.azure_resource_prefix
  service_short         = var.service_short
  service_name          = var.service_name
  docker_image          = var.docker_image
  postgres_version      = var.server_version
  postgres_url          = module.postgres.url

  host_name         = module.postgres.host
  database_name     = module.postgres.name
  workspace_id      = var.airbyte_enabled ? module.infrastructure_secrets.map.AIRBYTE-WORKSPACE-ID : null
  client_id         = var.airbyte_enabled ? module.infrastructure_secrets.map.AIRBYTE-CLIENT-ID : null
  client_secret     = var.airbyte_enabled ? module.infrastructure_secrets.map.AIRBYTE-CLIENT-SECRET : null
  repl_password     = var.airbyte_enabled ? module.infrastructure_secrets.map.AIRBYTE-REPLICATION-PASSWORD : null
  server_url        = "https://airbyte-${var.namespace}.${module.cluster_data.ingress_domain}"
  connection_status = var.connection_status

  cluster           = var.cluster
  namespace         = var.namespace
  gcp_taxonomy_id   = "6035056991658002237"
  gcp_policy_tag_id = "5001017932158544163"
  gcp_keyring       = "capt-key-ring"
  gcp_key           = "capt-key"


  config_map_ref = module.application_configuration.kubernetes_config_map_name
  secret_ref     = module.application_configuration.kubernetes_secret_name
  cpu            = module.cluster_data.configuration_map.cpu_min

  use_azure = var.deploy_azure_backing_services
  gcp_bq_sa = var.airbyte_enabled ? module.infrastructure_secrets.map.AIRBYTE-BQ-SA : null
}

## Airbyte module variables

variable "airbyte_enabled" { default = false }

variable "connection_status" {
  type        = string
  default     = "inactive"
  description = "Connection status, either active or inactive"
}

locals {
  gcp_dataset_name = replace("${var.service_short}_airbyte_${var.environment}", "-", "_")
}
