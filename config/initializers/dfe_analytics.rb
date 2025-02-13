DfE::Analytics.configure do |config|
  # Whether to log events instead of sending them to BigQuery.
  #
  # config.log_only = true
  config.log_only = (%w[development test].include?(ENV["RAILS_ENV"]) || ENV["ENVIRONMENT_NAME"].start_with?("review"))

  # Whether to use ActiveJob or dispatch events immediately.
  #
  # config.async = true

  # Which ActiveJob queue to put events on
  #
  # config.queue = :default

  # The name of the BigQuery table we’re writing to.
  #
  # config.bigquery_table_name = ENV['BIGQUERY_TABLE_NAME']

  # The name of the BigQuery project we’re writing to.
  #
  # config.bigquery_project_id = ENV['BIGQUERY_PROJECT_ID']

  # The name of the BigQuery dataset we're writing to.
  #
  # config.bigquery_dataset = ENV['BIGQUERY_DATASET']

  # Service account JSON key for the BigQuery API. See
  # https://cloud.google.com/bigquery/docs/authentication/service-account-file
  #
  # config.bigquery_api_json_key = ENV['BIGQUERY_API_JSON_KEY']

  # Passed directly to the retries: option on the BigQuery client
  #
  # config.bigquery_retries = 3

  # Passed directly to the timeout: option on the BigQuery client
  #
  # config.bigquery_timeout = 120

  # A proc which returns true or false depending on whether you want to
  # enable analytics. You might want to hook this up to a feature flag or
  # environment variable.
  #
  config.enable_analytics = proc { Rails.env.production? }

  # Enable entity table check job
  #
  config.entity_table_checks_enabled = true

  # The environment we’re running in. This value will be attached
  # to all events we send to BigQuery.
  #
  # config.environment = ENV.fetch('RAILS_ENV', 'development')

  config.azure_federated_auth = ENV.include? "GOOGLE_CLOUD_CREDENTIALS"
end

# Patch to send name / dob data to DfE analytics only for FE claims
# The attributes need to be listed in config/analytics.yml for
# `extract_model_attributes` to permit them, and they need to be attributes
# on the model for the analytics lint task to pass. As these fields are just
# an implementation detail specific to this DfE analytics workaround we define
# them here rather than in claim.rb.
Rails.application.config.to_prepare do
  Claim.class_eval do
    attribute :fe_first_name, :string
    attribute :fe_middle_name, :string
    attribute :fe_surname, :string
    attribute :fe_date_of_birth, :date
  end
end

module DfE::Analytics
  class << self
    alias_method :original_extract_model_attributes, :extract_model_attributes

    def extract_model_attributes(model, attributes = nil)
      if model.is_a?(Claim) && model.policy == Policies::FurtherEducationPayments
        # If attributes is not `nil` the gem's `extract_model_attributes`
        # method will use that otherwise it pulls the attributes from the
        # model.
        attributes ||= model.attributes

        attributes.merge!(
          "fe_first_name" => model.first_name,
          "fe_middle_name" => model.middle_name,
          "fe_surname" => model.surname,
          "fe_date_of_birth" => model.date_of_birth
        )
      end

      original_extract_model_attributes(model, attributes)
    end
  end
end
