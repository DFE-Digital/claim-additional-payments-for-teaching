require_relative "../../lib/application_insights/enhance_request_data_with_client_ip"
require_relative "../../lib/application_insights/enhance_track_request_with_client_ip"

instrumentation_key = ENV["APPINSIGHTS_INSTRUMENTATIONKEY"]

if instrumentation_key.present?
  Rails.application.configure do
    buffer_size = 1
    config.middleware.use ApplicationInsights::Rack::TrackRequest, instrumentation_key, buffer_size

    ApplicationInsights::UnhandledException.collect(instrumentation_key)
  end
end
