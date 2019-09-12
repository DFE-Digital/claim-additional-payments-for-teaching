# Extensions to the [ApplicationInsights-Ruby gem](https://github.com/microsoft/ApplicationInsights-Ruby)
# to add a client IP address to the payload of data sent to Application Insights
module ApplicationInsights
  module EnhanceRequestDataWithClientIp
    # Adds the client IP address to the properties hash sent to Application Insights.
    # This is stored in the customDimensions field in the requests table in Application Insights
    def client_ip=(client_ip)
      properties["clientIp"] = client_ip if client_ip.present?
    end
  end
end

ApplicationInsights::Channel::Contracts::RequestData.include ApplicationInsights::EnhanceRequestDataWithClientIp
