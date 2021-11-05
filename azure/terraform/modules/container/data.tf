data "azurerm_application_insights" "app_ai" {
  name                = format("%s-%s", var.app_rg_name, "ai")
  resource_group_name = var.app_rg_name
}

data "azurerm_container_registry" "acr" {
  name                = format("%s%s", var.rg_prefix, "contreg")
  resource_group_name = format("%s-%s", var.rg_prefix, "contreg")
}

data "azurerm_key_vault" "secrets_kv" {
  name                = format("%s-%s", var.rg_prefix, "secrets-kv")
  resource_group_name = format("%s-%s", var.rg_prefix, "secrets")
}


data "azurerm_key_vault_secret" "AdminAllowedIPs" {
  name         = "AdminAllowedIPs"
  key_vault_id = data.azurerm_key_vault.secrets_kv.id
}

data "azurerm_key_vault_secret" "DfeSignInApiClientId" {
  name         = "DfeSignInApiClientId"
  key_vault_id = data.azurerm_key_vault.secrets_kv.id
}
data "azurerm_key_vault_secret" "DfeSignInApiEndpoint" {
  name         = "DfeSignInApiEndpoint"
  key_vault_id = data.azurerm_key_vault.secrets_kv.id
}
data "azurerm_key_vault_secret" "DfeSignInApiSecret" {
  name         = "DfeSignInApiSecret"
  key_vault_id = data.azurerm_key_vault.secrets_kv.id
}
data "azurerm_key_vault_secret" "DfeSignInIdentifier" {
  name         = "DfeSignInIdentifier"
  key_vault_id = data.azurerm_key_vault.secrets_kv.id
}
data "azurerm_key_vault_secret" "DfeSignInIssuer" {
  name         = "DfeSignInIssuer"
  key_vault_id = data.azurerm_key_vault.secrets_kv.id
}
data "azurerm_key_vault_secret" "DfeSignInRedirectBaseUrl" {
  name         = "DfeSignInRedirectBaseUrl"
  key_vault_id = data.azurerm_key_vault.secrets_kv.id
}
data "azurerm_key_vault_secret" "DfeSignInSecret" {
  name         = "DfeSignInSecret"
  key_vault_id = data.azurerm_key_vault.secrets_kv.id
}
data "azurerm_key_vault_secret" "DQTClientHeaders" {
  name         = "DqtClientHeaders"
  key_vault_id = data.azurerm_key_vault.secrets_kv.id
}
data "azurerm_key_vault_secret" "DQTClientHost" {
  name         = "DqtClientHost"
  key_vault_id = data.azurerm_key_vault.secrets_kv.id
}
data "azurerm_key_vault_secret" "DQTClientParams" {
  name         = "DqtClientParams"
  key_vault_id = data.azurerm_key_vault.secrets_kv.id
}
data "azurerm_key_vault_secret" "DatabasePassword" {
  name         = "DatabasePassword"
  key_vault_id = data.azurerm_key_vault.secrets_kv.id
}
data "azurerm_key_vault_secret" "DatabaseUsername" {
  name         = "DatabaseUsername"
  key_vault_id = data.azurerm_key_vault.secrets_kv.id
}
data "azurerm_key_vault_secret" "SecretKeyBase" {
  name         = "SecretKeyBase"
  key_vault_id = data.azurerm_key_vault.secrets_kv.id
}
data "azurerm_key_vault_secret" "LogstashHost" {
  name         = "LogstashHost"
  key_vault_id = data.azurerm_key_vault.secrets_kv.id
}
data "azurerm_key_vault_secret" "NotifyApiKey" {
  name         = "NotifyApiKey"
  key_vault_id = data.azurerm_key_vault.secrets_kv.id
}
data "azurerm_key_vault_secret" "RollbarInfraToken" {
  name         = "RollbarAccessToken"
  key_vault_id = data.azurerm_key_vault.secrets_kv.id
}
data "azurerm_key_vault_secret" "DqtProxyApiKey" {
  name         = "DqtProxyApiKey"
  key_vault_id = data.azurerm_key_vault.secrets_kv.id
}

data "azurerm_key_vault_secret" "ordnancesurveyapibaseurl" {
  name         = "OrdnanceSurveyAPIBaseURL"
  key_vault_id = data.azurerm_key_vault.secrets_kv.id
}

data "azurerm_key_vault_secret" "ordnancesurveyclientparms" {
  name         = "OrdnanceSurveyClientParams"
  key_vault_id = data.azurerm_key_vault.secrets_kv.id
}

data "azurerm_key_vault_secret" "StorageBucket" {
  name         = "StorageBucket"
  key_vault_id = data.azurerm_key_vault.secrets_kv.id
}

data "azurerm_key_vault_secret" "StorageCredentials" {
  name         = "StorageCredentials"
  key_vault_id = data.azurerm_key_vault.secrets_kv.id
}

data "azurerm_key_vault_secret" "DQTBearerBaseUrl" {
  name         = "DQTBearerBaseUrl"
  key_vault_id = data.azurerm_key_vault.secrets_kv.id
}

data "azurerm_key_vault_secret" "DQTBearerGrantType" {
  name         = "DQTBearerGrantType"
  key_vault_id = data.azurerm_key_vault.secrets_kv.id
}

data "azurerm_key_vault_secret" "DQTBearerScope" {
  name         = "DQTBearerScope"
  key_vault_id = data.azurerm_key_vault.secrets_kv.id
}

data "azurerm_key_vault_secret" "DQTBearerClientId" {
  name         = "DQTBearerClientId"
  key_vault_id = data.azurerm_key_vault.secrets_kv.id
}

data "azurerm_key_vault_secret" "DqtBearerClientSecret" {
  name         = "DqtBearerClientSecret"
  key_vault_id = data.azurerm_key_vault.secrets_kv.id
}

data "azurerm_key_vault_secret" "DQTBaseUrl" {
  name         = "DQTBaseUrl"
  key_vault_id = data.azurerm_key_vault.secrets_kv.id
}

data "azurerm_key_vault_secret" "DQTSubscriptionKey" {
  name         = "DQTSubscriptionKey"
  key_vault_id = data.azurerm_key_vault.secrets_kv.id
}

data "azurerm_key_vault_secret" "GTMAnalytics" {
  name         = "GTMAnalytics"
  key_vault_id = data.azurerm_key_vault.secrets_kv.id
}

# data "azurerm_key_vault_secret" "TeacherPaymentsDevVspSamlEncryption2Key" {
#   name         = "TeacherPaymentsDevVspSamlEncryption2Key"
#   key_vault_id = data.azurerm_key_vault.secrets_kv.id
# }

# data "azurerm_app_service" "app_vsp_as" {
#   name                = format("%s-%s", var.app_rg_name, "vsp-as")
#   resource_group_name = var.app_rg_name
# }
