module Verify
  IDENTITY_VERIFIED_SCENARIO = "IDENTITY_VERIFIED".freeze
  AUTHENTICATION_FAILED_SCENARIO = "AUTHENTICATION_FAILED".freeze
  NO_AUTHENTICATION_SCENARIO = "NO_AUTHENTICATION".freeze

  class << self
    attr_accessor :configuration
  end

  def self.configure
    self.configuration ||= Configuration.new
    yield(configuration)
  end

  class Configuration
    attr_accessor :vsp_host
  end
end

require_relative "verify/service_provider"
require_relative "verify/authentication_request"
require_relative "verify/response"
require_relative "verify/response_error"
