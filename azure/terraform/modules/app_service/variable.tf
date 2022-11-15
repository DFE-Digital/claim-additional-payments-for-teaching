variable "app_rg_name" {
  type        = string
  description = "Resource group for the application"
}
variable "input_container_version" {
  type        = string
  description = "Container version fed in from Release"
}
variable "rg_prefix" {
  type        = string
  description = "The prefix to be used for all resources"
}
variable "rg_location" {
  type        = string
  description = "The location of the resource group and the resources"
}
variable "common_tags" {
  type        = map(string)
  description = "Map of the mandatory standard DfE tags"
}
variable "app_name" {
  type        = string
  description = "Identifier for review apps"
}
variable "db_host" {
  type        = string
  description = "FQDN of the postgres app database server"
}
variable "db_name" {
  type        = string
  description = "Name of the postgres app database"
}
variable "db_admin_username" {
  type        = string
  description = "Username of the postgres app database server administrator"
}
variable "environment" {
  type        = string
  description = "Name of the application environment"
  default     = null
}
variable "canonical_hostname" {
  type        = string
  description = "External domain name for the app service"
  default     = null
}
variable "ssl_hostnames" {
  type        = list
  description = "External domain names for the app service. They must be declared as SANs on the SSL certificate"
}
variable "bypass_dfe_sign_in" {
  type        = bool
  description = "Bypass DFE Sign-In authentication and use a default role"
}

variable "pr_number" {
  type        = string
  description = "Pull Request Number for Review App"
}

variable "suppress_dfe_analytics_init" {
  type        = string
  description = "Stop DfE-analytics from booting"
  default     = null
}

variable "enable_basic_auth" {
  type        = bool
  description = "Enable basic HTTP authentication"
  default     = false
}

variable keyvault_cert_name {
  type        = string
  description = "Key vault certificate for app service"
}

locals {
  stash_port         = var.rg_prefix == "s118p01" ? "23888" : "17000"

  app_service_name = var.app_name == null ? format("%s-%s", var.app_rg_name, "as") : format("%s-%s-%s", var.app_rg_name, var.app_name, "as")
  canonical_hostname = var.canonical_hostname != null ? var.canonical_hostname : "${local.app_service_name}.azurewebsites.net"

  docker_registry = "index.docker.io"
  default_environment_variables = {
    "ADMIN_ALLOWED_IPS"              = data.azurerm_key_vault_secret.AdminAllowedIPs.value
    "APPINSIGHTS_INSTRUMENTATIONKEY" = data.azurerm_application_insights.app_ai.instrumentation_key
    "BIGQUERY_TABLE_NAME"            = data.azurerm_key_vault_secret.BigqueryTableName.value
    "BIGQUERY_PROJECT_ID"            = data.azurerm_key_vault_secret.BigqueryProjectId.value
    "BIGQUERY_DATASET"               = data.azurerm_key_vault_secret.BigqueryDataset.value
    "BIGQUERY_API_JSON_KEY"          = data.azurerm_key_vault_secret.BigqueryApiJsonKey.value
    "CANONICAL_HOSTNAME"             = local.canonical_hostname
    "DFE_SIGN_IN_API_CLIENT_ID"      = data.azurerm_key_vault_secret.DfeSignInApiClientId.value
    "DFE_SIGN_IN_API_ENDPOINT"       = data.azurerm_key_vault_secret.DfeSignInApiEndpoint.value
    "DFE_SIGN_IN_API_SECRET"         = data.azurerm_key_vault_secret.DfeSignInApiSecret.value
    "DFE_SIGN_IN_IDENTIFIER"         = data.azurerm_key_vault_secret.DfeSignInIdentifier.value
    "DFE_SIGN_IN_ISSUER"             = data.azurerm_key_vault_secret.DfeSignInIssuer.value
    "DFE_SIGN_IN_REDIRECT_BASE_URL"  = data.azurerm_key_vault_secret.DfeSignInRedirectBaseUrl.value
    "DFE_SIGN_IN_SECRET"             = data.azurerm_key_vault_secret.DfeSignInSecret.value
    "DFE_TEACHERS_PAYMENT_SERVICE_DATABASE_HOST"     = var.db_host
    "DFE_TEACHERS_PAYMENT_SERVICE_DATABASE_NAME"     = var.db_name
    "DFE_TEACHERS_PAYMENT_SERVICE_DATABASE_PASSWORD" = data.azurerm_key_vault_secret.DatabasePassword.value
    "DFE_TEACHERS_PAYMENT_SERVICE_DATABASE_USERNAME" = "${var.db_admin_username}@${var.db_host}"
    "DQT_BEARER_BASE_URL"                            = data.azurerm_key_vault_secret.DQTBearerBaseUrl.value
    "DQT_BEARER_GRANT_TYPE"                          = data.azurerm_key_vault_secret.DQTBearerGrantType.value
    "DQT_BEARER_SCOPE"                               = data.azurerm_key_vault_secret.DQTBearerScope.value
    "DQT_BEARER_CLIENT_ID"                           = data.azurerm_key_vault_secret.DQTBearerClientId.value
    "DQT_BEARER_CLIENT_SECRET"                       = data.azurerm_key_vault_secret.DqtBearerClientSecret.value
    "DQT_BASE_URL"                                   = data.azurerm_key_vault_secret.DQTBaseUrl.value
    "DQT_SUBSCRIPTION_KEY"                           = data.azurerm_key_vault_secret.DQTSubscriptionKey.value
    "DQT_API_URL"                                    = data.azurerm_key_vault_secret.DQTApiUrl.value
    "DQT_API_KEY"                                    = data.azurerm_key_vault_secret.DQTApiKey.value
    "ENVIRONMENT_NAME"                               = var.environment
    "GOOGLE_ANALYTICS_ID"                            = ""
    "GTM_ANALYTICS"                                  = data.azurerm_key_vault_secret.GTMAnalytics.value
    "LOGSTASH_HOST"                                  = data.azurerm_key_vault_secret.LogstashHost.value
    "LOGSTASH_PORT"                                  = local.stash_port
    "NOTIFY_API_KEY"                                 = data.azurerm_key_vault_secret.NotifyApiKey.value
    "ORDNANCE_SURVEY_CLIENT_PARAMS"                  = data.azurerm_key_vault_secret.ordnancesurveyclientparms.value
    "ORDNANCE_SURVEY_API_BASE_URL"                   = data.azurerm_key_vault_secret.ordnancesurveyapibaseurl.value
    "RAILS_ENV"                                      = "production"
    "RAILS_SERVE_STATIC_FILES"                       = "true"
    "ROLLBAR_ACCESS_TOKEN"                           = data.azurerm_key_vault_secret.RollbarInfraToken.value
    "SECRET_KEY_BASE"                                = data.azurerm_key_vault_secret.SecretKeyBase.value
    "STORAGE_BUCKET"                                 = data.azurerm_key_vault_secret.StorageBucket.value
    "STORAGE_CREDENTIALS"                            = data.azurerm_key_vault_secret.StorageCredentials.value
    "WORKER_COUNT"                                   = "4"
    "DOCKER_REGISTRY_SERVER_URL"                     = "https://${local.docker_registry}"
    "BYPASS_DFE_SIGN_IN"                             = var.bypass_dfe_sign_in
    "PR_NUMBER"                                      = var.pr_number
  }

  environment_variables = var.enable_basic_auth ? merge(local.default_environment_variables, {
      BASIC_AUTH_USERNAME = data.azurerm_key_vault_secret.BasicAuthUsername[0].value
      BASIC_AUTH_PASSWORD = data.azurerm_key_vault_secret.BasicAuthPassword[0].value
    }) : local.default_environment_variables
  cert_set = var.keyvault_cert_name != null ? toset([var.keyvault_cert_name]) : toset([])
  # app_service_cert_name = "${data.azurerm_key_vault.secrets_kv.name}-${var.keyvault_cert_name}"
}
