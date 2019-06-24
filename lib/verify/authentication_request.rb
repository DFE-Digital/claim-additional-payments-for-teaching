require "verify/service_provider"

module Verify
  # SAML Authentication Request used to start the verification user journey.
  #
  # Use by calling AuthenticationRequest.generate to generate a new
  # authentication request via the Verify Service Provider
  class AuthenticationRequest
    attr_reader :saml_request, :request_id, :sso_location

    def initialize(saml_request:, request_id:, sso_location:)
      @saml_request = saml_request
      @request_id = request_id
      @sso_location = sso_location
    end

    def self.generate
      request = Verify::ServiceProvider.new.generate_request

      new(
        saml_request: request["samlRequest"],
        request_id: request["requestId"],
        sso_location: request["ssoLocation"]
      )
    end
  end
end
