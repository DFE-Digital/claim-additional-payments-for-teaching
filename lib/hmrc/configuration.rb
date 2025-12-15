module Hmrc
  class Configuration
    attr_accessor :base_url, :client_id, :client_secret, :enabled, :logger, :http_client

    def initialize
      self.base_url = nil
      self.client_id = nil
      self.client_secret = nil
      self.enabled = false
      self.logger = Rails.logger
      self.http_client = Faraday
    end

    def enabled?
      enabled == true
    end
  end
end
