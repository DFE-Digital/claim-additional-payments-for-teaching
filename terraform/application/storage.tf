module "storage_private" {
  source = "./vendor/modules/aks//aks/storage_account"

  name                          = "pv"
  environment                   = var.environment
  azure_resource_prefix         = var.azure_resource_prefix
  service_short                 = var.service_short
  config_short                  = var.config_short
  public_network_access_enabled = false
  cluster_configuration_map     = module.cluster_data.configuration_map
  use_private_storage           = true

  # Create containers for the application (all containers are private)
  containers = [
    { name = "files" }
  ]

  # Configure blob lifecycle management (default: delete after 7 days)
  container_delete_retention_days = var.container_delete_retention_days

  blob_delete_after_days = var.blob_delete_after_days

}