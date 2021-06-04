module Dqt
  class Client
    def initialize(
      headers: Dqt.configuration.client.headers,
      host: Dqt.configuration.client.host,
      params: Dqt.configuration.client.params,
      port: Dqt.configuration.client.port
    )
      self.headers = headers
      self.host = host
      self.params = params
      self.port = port
    end

    def api
      @api ||= Api.new(client: self)
    end

    def get(path: "/", params: {})
      request(method: :get, path: path, params: params, body: nil)
    end

    private

    attr_accessor :headers, :host, :params, :port

    # Accessing readers with send because < Ruby 2.7
    def request(method:, path: "/", params: {}, body: {})
      headers = {
        'Content-Type': "application/json"
      }.merge(send(:headers))

      body = {request: body}.to_json unless body.blank?
      params = params.merge(send(:params))
      url = url(path)

      response = Response.new(
        response: Typhoeus.public_send(
          method,
          url,
          headers: headers,
          params: params,
          body: body
        )
      )

      if [*0..199, *300..599].include? response.code
        raise ResponseError.new(
          {
            request: {
              method: method,
              url: url,
              headers: headers,
              params: params,
              body: body
            },
            response: {
              body: response.body,
              code: response.code
            }
          }
        )
      end

      response.body
    end

    def url(path)
      "#{host}#{":" unless port.nil?}#{port}#{path}"
    end
  end
end
