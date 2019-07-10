module Verify
  IDENTITY_VERIFIED_SCENARIO = "IDENTITY_VERIFIED".freeze
  AUTHENTICATION_FAILED_SCENARIO = "AUTHENTICATION_FAILED".freeze
  NO_AUTHENTICATION_SCENARIO = "NO_AUTHENTICATION".freeze

  def self.configure
    yield self
  end

  def self.config
    @config ||= {}
  end

  def self.vsp_host=(vsp_host)
    config[:vsp_host] = vsp_host
  end

  def self.vsp_host
    config[:vsp_host]
  end
end

require_relative "verify/service_provider"
require_relative "verify/authentication_request"
require_relative "verify/response"
require_relative "verify/response_error"
