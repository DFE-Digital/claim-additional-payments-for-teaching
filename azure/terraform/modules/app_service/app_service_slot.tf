resource "azurerm_app_service_slot" "app_as_slot" {
  name                = "staging"
  app_service_name    = azurerm_app_service.app_as.name
  resource_group_name = var.app_rg_name
  location            = var.rg_location
  app_service_plan_id = var.app_asp_id
  https_only          = true

  site_config {
    default_documents = [
      "Default.htm",
      "Default.html",
      "Default.asp",
      "index.htm",
      "index.html",
      "iisstart.htm",
      "default.aspx",
      "index.php",
      "hostingstart.html",
    ]
    health_check_path         = "/healthcheck"
    use_32_bit_worker_process = true
    linux_fx_version          = format("%s%s", "DOCKER|dfedigital/teacher-payments-service:", var.input_container_version)
    # linux_fx_version = format("%s%s", "DOCKER|s118d01contreg.azurecr.io/teacher-payments-service:", var.input_container_version)
  }

  app_settings = {
    "ADMIN_ALLOWED_IPS"                              = data.azurerm_key_vault_secret.AdminAllowedIPs.value
    "APPINSIGHTS_INSTRUMENTATIONKEY"                 = data.azurerm_application_insights.app_ai.instrumentation_key
    "CANONICAL_HOSTNAME"                             = local.verify_entity_id
    "DFE_SIGN_IN_API_CLIENT_ID"                      = data.azurerm_key_vault_secret.DfeSignInApiClientId.value
    "DFE_SIGN_IN_API_ENDPOINT"                       = data.azurerm_key_vault_secret.DfeSignInApiEndpoint.value
    "DFE_SIGN_IN_API_SECRET"                         = data.azurerm_key_vault_secret.DfeSignInApiSecret.value
    "DFE_SIGN_IN_IDENTIFIER"                         = data.azurerm_key_vault_secret.DfeSignInIdentifier.value
    "DFE_SIGN_IN_ISSUER"                             = data.azurerm_key_vault_secret.DfeSignInIssuer.value
    "DFE_SIGN_IN_REDIRECT_BASE_URL"                  = data.azurerm_key_vault_secret.DfeSignInRedirectBaseUrl.value
    "DFE_SIGN_IN_SECRET"                             = data.azurerm_key_vault_secret.DfeSignInSecret.value
    "DFE_TEACHERS_PAYMENT_SERVICE_DATABASE_HOST"     = format("%s.%s", format("%s-%s", var.app_rg_name, "db"), "postgres.database.azure.com")
    "DFE_TEACHERS_PAYMENT_SERVICE_DATABASE_NAME"     = local.environment
    "DFE_TEACHERS_PAYMENT_SERVICE_DATABASE_PASSWORD" = data.azurerm_key_vault_secret.DatabasePassword.value
    "DFE_TEACHERS_PAYMENT_SERVICE_DATABASE_USERNAME" = format("%s@%s", data.azurerm_key_vault_secret.DatabaseUsername.value, format("%s-%s", var.app_rg_name, "db")) # "tps_development@s118d01-app-db"
    "DQT_BEARER_BASE_URL"                            = data.azurerm_key_vault_secret.DQTBearerBaseUrl.value
    "DQT_BEARER_GRANT_TYPE"                          = data.azurerm_key_vault_secret.DQTBearerGrantType.value
    "DQT_BEARER_SCOPE"                               = data.azurerm_key_vault_secret.DQTBearerScope.value
    "DQT_BEARER_CLIENT_ID"                           = data.azurerm_key_vault_secret.DQTBearerClientId.value
    "DQT_BEARER_CLIENT_SECRET"                       = data.azurerm_key_vault_secret.DqtBearerClientSecret.value
    "DQT_BASE_URL"                                   = data.azurerm_key_vault_secret.DQTBaseUrl.value
    "DQT_SUBSCRIPTION_KEY"                           = data.azurerm_key_vault_secret.DQTSubscriptionKey.value
    "ENVIRONMENT_NAME"                               = local.environment
    "GECKOBOARD_API_KEY"                             = data.azurerm_key_vault_secret.GeckoboardAPIKey.value
    "GOOGLE_ANALYTICS_ID"                            = ""
    "GTM_ANALYTICS"                                  = data.azurerm_key_vault_secret.GTMAnalytics.value
    "LOGSTASH_HOST"                                  = data.azurerm_key_vault_secret.LogstashHost.value
    "LOGSTASH_PORT"                                  = local.stash_port
    "NOTIFY_API_KEY"                                 = data.azurerm_key_vault_secret.NotifyApiKey.value
    "ORDNANCE_SURVEY_CLIENT_PARAMS"                  = data.azurerm_key_vault_secret.ordnancesurveyclientparms.value
    "ORDNANCE_SURVEY_API_BASE_URL"                   = data.azurerm_key_vault_secret.ordnancesurveyapibaseurl.value
    "RAILS_ENV"                                      = "production" #local.environment
    "RAILS_SERVE_STATIC_FILES"                       = "true"
    "ROLLBAR_ACCESS_TOKEN"                           = data.azurerm_key_vault_secret.RollbarInfraToken.value
    "SECRET_KEY_BASE"                                = data.azurerm_key_vault_secret.SecretKeyBase.value
    "STORAGE_BUCKET"                                 = data.azurerm_key_vault_secret.StorageBucket.value
    "STORAGE_CREDENTIALS"                            = data.azurerm_key_vault_secret.StorageCredentials.value
    "WORKER_COUNT"                                   = "2"
    "DOCKER_REGISTRY_SERVER_URL"                     = "https://index.docker.io"
  }

  tags = merge({
    },
    var.common_tags
  )
}
