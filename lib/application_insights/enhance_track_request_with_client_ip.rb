# Extensions to the [ApplicationInsights-Ruby gem](https://github.com/microsoft/ApplicationInsights-Ruby)
# to allow IP addresses to be sent and retrieved by Application Insights.
module ApplicationInsights
  module EnhanceTrackRequestWithClientIp
    # Returns a hash of options to be passed to `request_data`. Overrides `options_hash`
    # in the Application Insights gem to add the request IP to the hash
    def options_hash(request)
      super.merge(client_ip: request.ip)
    end

    # Returns the data to be sent to Application Insights. Overrides `request_data` in the
    # Application Insights gem to add the client IP to the payload
    def request_data(request_id, start_time, duration, status, success, options)
      request_data = super
      request_data.client_ip = options[:client_ip]
      request_data
    end
  end
end

ApplicationInsights::Rack::TrackRequest.prepend ApplicationInsights::EnhanceTrackRequestWithClientIp
