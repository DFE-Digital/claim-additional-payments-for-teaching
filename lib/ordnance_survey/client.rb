module OrdnanceSurvey
  class Client
    def initialize(
      base_url: OrdnanceSurvey.configuration.client.base_url,
      params: OrdnanceSurvey.configuration.client.params
    )
      self.base_url = base_url
      self.params = params
    end

    def api
      @api ||= Api.new(client: self)
    end

    def get(path: "/", params: {})
      request(method: :get, path: path, params: params)
    end

    private

    attr_accessor :api_key, :base_url, :headers, :params

    # Accessing readers with send because < Ruby 2.7
    def request(method:, path: "/", params: {}, body: {})
      headers = {
        'Content-Type': "application/json"
      }

      params = params.merge(send(:params))

      response = Response.new(
        response: Typhoeus.public_send(
          method,
          url(path),
          headers: headers,
          params: params,
          body: body
        )
      )

      return nil if response.code == 404

      raise ResponseError.new(response) if [*0..199, *300..403, *405..599].include? response.code

      response.body
    end

    def url(path)
      "#{base_url}#{path}"
    end
  end
end
