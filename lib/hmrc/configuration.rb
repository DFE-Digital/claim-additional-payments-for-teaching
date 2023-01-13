module Hmrc
  class Configuration
    attr_accessor :base_url, :client_id, :client_secret

    def initialize
      self.base_url = nil
      self.client_id = nil
      self.client_secret = nil
    end
  end
end
