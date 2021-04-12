module Dqt
  class Client
    def initialize(
      host: Dqt.configuration.client.host,
      port: nil
    )
      self.host = host
      self.port = port
    end

    def api
      @api ||= Api.new(client: self)
    end

    def get(path: "/", params: {})
      request(method: :get, path: path, params: params, body: nil)
    end

    private

    attr_accessor :host, :port

    def request(method:, path: "/", params: {}, body: {})
      headers = {
        'Content-Type': "application/json"
      }

      body = {request: body}.to_json unless body.blank?

      response = Response.new(
        response: Typhoeus.public_send(
          method,
          url(path),
          headers: headers,
          params: params,
          body: body
        )
      )

      raise ResponseError.new(response) if [*0..199, *300..599].include? response.code

      response.body
    end

    def url(path)
      "#{host}#{":" unless port.nil?}#{port}#{path}"
    end
  end
end
