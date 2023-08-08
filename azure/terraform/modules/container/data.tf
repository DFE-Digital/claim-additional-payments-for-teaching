data "azurerm_application_insights" "app_ai" {
  name                = format("%s-%s", var.app_rg_name, "ai")
  resource_group_name = var.app_rg_name
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

data "azurerm_key_vault_secret" "DQTApiUrl" {
  name         = "DQTApiUrl"
  key_vault_id = data.azurerm_key_vault.secrets_kv.id
}
data "azurerm_key_vault_secret" "DQTApiKey" {
  name         = "DQTApiKey"
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

data "azurerm_key_vault_secret" "BigqueryTableName" {
  name         = "BigqueryTableName"
  key_vault_id = data.azurerm_key_vault.secrets_kv.id
}

data "azurerm_key_vault_secret" "BigqueryProjectId" {
  name         = "BigqueryProjectId"
  key_vault_id = data.azurerm_key_vault.secrets_kv.id
}

data "azurerm_key_vault_secret" "BigqueryDataset" {
  name         = "BigqueryDataset"
  key_vault_id = data.azurerm_key_vault.secrets_kv.id
}

data "azurerm_key_vault_secret" "BigqueryApiJsonKey" {
  name         = "BigqueryApiJsonKey"
  key_vault_id = data.azurerm_key_vault.secrets_kv.id
}

data "azurerm_key_vault_secret" "HMRCBaseURL" {
  name         = "HMRCBaseURL"
  key_vault_id = data.azurerm_key_vault.secrets_kv.id
}
data "azurerm_key_vault_secret" "HMRCClientID" {
  name         = "HMRCClientID"
  key_vault_id = data.azurerm_key_vault.secrets_kv.id
}
data "azurerm_key_vault_secret" "HMRCClientSecret" {
  name         = "HMRCClientSecret"
  key_vault_id = data.azurerm_key_vault.secrets_kv.id
}
data "azurerm_key_vault_secret" "HMRCBankValidationEnabled" {
  name         = "HMRCBankValidationEnabled"
  key_vault_id = data.azurerm_key_vault.secrets_kv.id
}
data "azurerm_key_vault_secret" "TidSignInClientId" {
  name         = "TidSignInClientId"
  key_vault_id = data.azurerm_key_vault.secrets_kv.id
}
data "azurerm_key_vault_secret" "TidSignInSecret" {
  name         = "TidSignInSecret"
  key_vault_id = data.azurerm_key_vault.secrets_kv.id
}
data "azurerm_key_vault_secret" "TidBaseUrl" {
  name         = "TidBaseUrl"
  key_vault_id = data.azurerm_key_vault.secrets_kv.id
}
data "azurerm_key_vault_secret" "TidSignInApiEndpoint" {
  name         = "TidSignInApiEndpoint"
  key_vault_id = data.azurerm_key_vault.secrets_kv.id
}
data "azurerm_key_vault_secret" "TidSignInIssuer" {
  name         = "TidSignInIssuer"
  key_vault_id = data.azurerm_key_vault.secrets_kv.id
}
