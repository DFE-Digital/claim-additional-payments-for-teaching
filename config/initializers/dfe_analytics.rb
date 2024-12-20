DfE::Analytics.configure do |config|
  config.queue = :analytics
  config.environment = HostingEnvironment.environment_name
  config.entity_table_checks_enabled = true

  config.enable_analytics =
    proc do
      disabled_by_default = Rails.env.development?
      ENV.fetch("BIGQUERY_DISABLE", disabled_by_default.to_s) != "true"
    end
  config.azure_federated_auth = ENV.include? "GOOGLE_CLOUD_CREDENTIALS"
end
