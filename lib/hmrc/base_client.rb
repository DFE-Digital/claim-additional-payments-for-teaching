module Hmrc
  class BaseClient
    def initialize(base_url:, client_id:, client_secret:, http_client:, logger:)
      self.base_url = base_url
      self.client_id = client_id
      self.client_secret = client_secret
      self.http_client = http_client
      self.logger = logger
    end

    private

    attr_accessor :base_url, :client_id, :client_secret, :http_client, :logger

    def post_request!(path, payload, headers = nil, timeout: nil)
      response = http_client.post(
        "#{base_url}#{path}",
        payload,
        headers
      ) do |request|
        request.options.timeout = timeout if timeout
        request.options.open_timeout = timeout if timeout
      end

      if !response.success?
        logger.info("HMRC API error: response code #{response.status}")
        raise Hmrc::ResponseError.new(response)
      end

      response
    end

    def get_request!(path, headers = nil, timeout: nil)
      response = http_client.get(
        "#{base_url}#{path}",
        nil,
        headers
      ) do |request|
        request.options.timeout = timeout if timeout
        request.options.open_timeout = timeout if timeout
      end

      if !response.success?
        logger.info("HMRC API error: response code #{response.status}")
        raise Hmrc::ResponseError.new(response)
      end

      response
    end
  end
end
