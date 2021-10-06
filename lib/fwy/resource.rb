module Fwy
  class Resource
    attr_reader :client

    def initialize(client)
      @client = client
    end

    private

    def get_request(url, params: {}, headers: {})
      handle_response client.connection.get(url, params, headers.merge(default_headers))
    end

    def handle_response(response)
      case response.status
      when 400
        raise Error, "Your request was malformed. [#{response.status}: #{response.body["message"]}]"
      when 401
        raise Error, "You did not supply valid authentication credentials. [#{response.status}: #{response.body["message"]}]"
      when 403
        raise Error, "You are not allowed to perform that action. [#{response.status}: #{response.body["message"]}]"
      when 404
        return nil
      when 429
        raise Error, "Your request exceeded the API rate limit. [#{response.status}: #{response.body["message"]}]"
      when 500
        raise Error, "We were unable to perform the request due to server-side problems. [#{response.status}: #{response.body["message"]}]"
      when 503
        raise Error, "You have been rate limited for sending more than 20 requests per second. [#{response.status}: #{response.body["message"]}]"
      end

      response
    end

    private

    def default_headers
      {"Ocp-Apim-Subscription-Key" => ENV["FWY_SUBSCRIPTION_KEY"]}
    end
  end
end
