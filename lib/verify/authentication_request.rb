require "verify/service_provider"

module Verify
  class AuthenticationRequest
    attr_reader :saml_request, :request_id, :sso_location

    def initialize(saml_request:, request_id:, sso_location:)
      @saml_request = saml_request
      @request_id = request_id
      @sso_location = sso_location
    end
  end
end
