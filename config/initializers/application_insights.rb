instrumentation_key = ENV["APPINSIGHTS_INSTRUMENTATIONKEY"]

if instrumentation_key.present?
  Rails.application.configure do
    buffer_size = 1
    config.middleware.use ApplicationInsights::Rack::TrackRequest, instrumentation_key, buffer_size
  end
end
