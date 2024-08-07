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

  # FIXME: remove this line once the window has passed
  config.bigquery_maintenance_window = "09-08-2024 10:00..09-08-2024 11:00"
end
