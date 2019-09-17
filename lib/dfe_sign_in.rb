module DfeSignIn
  class ExternalServerError < StandardError; end

  class << self
    attr_accessor :configuration
  end

  def self.configure
    self.configuration ||= Configuration.new
    yield(configuration)
  end

  class Configuration
    attr_accessor :client_id,
      :secret,
      :base_url
  end
end

require_relative "dfe_sign_in/authenticated_session"
require_relative "dfe_sign_in/utils"
require_relative "dfe_sign_in/api/user"
