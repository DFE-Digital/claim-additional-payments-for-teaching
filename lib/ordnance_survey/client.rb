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
      uri = calculate_uri(path, params)

      response = connection.get(uri) do |request|
        params.each do |k, v|
          request.params[k] = v
        end
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

    def connection
      @connection ||= Faraday.new(
        params:,
        headers: {
          "Content-Type" => "application/json"
        }
      )
    end

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
