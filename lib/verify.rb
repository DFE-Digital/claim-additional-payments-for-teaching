module Verify
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
