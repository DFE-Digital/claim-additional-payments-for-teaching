resource "azurerm_container_group" "cont_grp_01" {
  name                = local.cont_grp_01_name
  location            = var.rg_location
  resource_group_name = var.app_rg_name
  os_type             = "Linux"

  # image_registry_credential {
  #   username = data.azurerm_container_registry.acr.admin_username
  #   password = data.azurerm_container_registry.acr.admin_password
  #   server   = data.azurerm_container_registry.acr.login_server
  # }

  container {
    name = local.cont_01_name
    # image = format("%s%s", "s118d01contreg.azurecr.io/teacher-payments-service:", var.container_version)
    image = format("%s%s", "dfedigital/teacher-payments-service:", var.container_version)

    cpu    = "1"
    memory = "1.5"

    environment_variables = {
      "ADMIN_ALLOWED_IPS"                              = data.azurerm_key_vault_secret.AdminAllowedIPs.value
      "APPINSIGHTS_INSTRUMENTATIONKEY"                 = data.azurerm_application_insights.app_ai.instrumentation_key
      "CANONICAL_HOSTNAME"                             = "not.required"
      "DFE_SIGN_IN_API_CLIENT_ID"                      = data.azurerm_key_vault_secret.DfeSignInApiClientId.value
      "DFE_SIGN_IN_API_ENDPOINT"                       = data.azurerm_key_vault_secret.DfeSignInApiEndpoint.value
      "DFE_SIGN_IN_API_SECRET"                         = data.azurerm_key_vault_secret.DfeSignInApiSecret.value
      "DFE_SIGN_IN_IDENTIFIER"                         = data.azurerm_key_vault_secret.DfeSignInIdentifier.value
      "DFE_SIGN_IN_ISSUER"                             = data.azurerm_key_vault_secret.DfeSignInIssuer.value
      "DFE_SIGN_IN_REDIRECT_BASE_URL"                  = data.azurerm_key_vault_secret.DfeSignInRedirectBaseUrl.value
      "DFE_SIGN_IN_SECRET"                             = data.azurerm_key_vault_secret.DfeSignInSecret.value
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
      "ORDNANCE_SURVEY_CLIENT_PARAMS"                  = data.azurerm_key_vault_secret.ordnancesurveyclientparms.value
      "ORDNANCE_SURVEY_API_BASE_URL"                   = data.azurerm_key_vault_secret.ordnancesurveyapibaseurl.value
      "NOTIFY_API_KEY"                                 = data.azurerm_key_vault_secret.NotifyApiKey.value
      "RAILS_ENV"                                      = "production"
      "RAILS_SERVE_STATIC_FILES"                       = "true"
      "ROLLBAR_ACCESS_TOKEN"                           = data.azurerm_key_vault_secret.RollbarInfraToken.value
      "SECRET_KEY_BASE"                                = data.azurerm_key_vault_secret.SecretKeyBase.value
      "STORAGE_BUCKET"                                 = data.azurerm_key_vault_secret.StorageBucket.value
      "STORAGE_CREDENTIALS"                            = data.azurerm_key_vault_secret.StorageCredentials.value
      "WORKER_COUNT"                                   = "2"
    }

    ports {
      port     = 443
      protocol = "TCP"
    }

    commands = ["bin/start-worker"]

  }

  tags = merge({
    },
    var.common_tags
  )
}

resource "azurerm_container_group" "cont_grp_02" {
  name                = local.cont_grp_02_name
  location            = var.rg_location
  resource_group_name = var.app_rg_name
  os_type             = "Linux"
  restart_policy      = "OnFailure"

  # image_registry_credential {
  #   username = data.azurerm_container_registry.acr.admin_username
  #   password = data.azurerm_container_registry.acr.admin_password
  #   server   = data.azurerm_container_registry.acr.login_server
  # }

  container {

    commands = ["bin/prepare-database"]

    environment_variables = {
      "ADMIN_ALLOWED_IPS"                              = data.azurerm_key_vault_secret.AdminAllowedIPs.value
      "APPINSIGHTS_INSTRUMENTATIONKEY"                 = data.azurerm_application_insights.app_ai.instrumentation_key
      "CANONICAL_HOSTNAME"                             = "not.required"
      "DFE_SIGN_IN_API_CLIENT_ID"                      = data.azurerm_key_vault_secret.DfeSignInApiClientId.value
      "DFE_SIGN_IN_API_ENDPOINT"                       = data.azurerm_key_vault_secret.DfeSignInApiEndpoint.value
      "DFE_SIGN_IN_API_SECRET"                         = data.azurerm_key_vault_secret.DfeSignInApiSecret.value
      "DFE_SIGN_IN_IDENTIFIER"                         = data.azurerm_key_vault_secret.DfeSignInIdentifier.value
      "DFE_SIGN_IN_ISSUER"                             = data.azurerm_key_vault_secret.DfeSignInIssuer.value
      "DFE_SIGN_IN_REDIRECT_BASE_URL"                  = data.azurerm_key_vault_secret.DfeSignInRedirectBaseUrl.value
      "DFE_SIGN_IN_SECRET"                             = data.azurerm_key_vault_secret.DfeSignInSecret.value
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
      "WORKER_COUNT"                                   = "2"

    }

    name  = local.cont_02_name
    image = format("%s%s", "dfedigital/teacher-payments-service:", var.container_version)
    # image  = format("%s%s", "s118d01contreg.azurecr.io/teacher-payments-service:", var.container_version)
    cpu    = "1"
    memory = "1.5"

    ports {
      port     = 443
      protocol = "TCP"
    }

  }

  tags = merge({
    },
    var.common_tags
  )
}
