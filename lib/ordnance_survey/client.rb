require "net/http"

module OrdnanceSurvey
  class Client
    def initialize(
      base_url: OrdnanceSurvey.configuration.client.base_url,
      params: OrdnanceSurvey.configuration.client.params
    )
      self.base_url = base_url
      self.params = params || {}
    end

    def api
      @api ||= Api.new(client: self)
    end

    def get(path: "/", params: {})
      params = params.merge(self.params)

      uri = calculate_uri(path, params)

      request = Net::HTTP::Get.new(uri)
      request["Content-Type"] = "application/json"

      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == "https") do |http|
        http.request(request)
      end

      wrapped_response = Response.new(
        response:
      )

      return nil if wrapped_response.code == 404

      raise ResponseError.new(wrapped_response) if [*0..199, *300..403, *405..599].include? wrapped_response.code.to_i

      wrapped_response.body
    end

    private

    attr_accessor :base_url, :params

    def calculate_uri(path, params)
      string = "#{base_url}#{path}"
      query_string = params.map { |k, v| "#{k}=#{v}" }.join("&")

      if params.any?
        string += "?#{query_string}"
      end

      URI(string)
    end
  end
end
