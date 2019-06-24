require "verify/authentication_request"

module Verify
  class AuthenticationsController < ApplicationController
    # Page where a new Verify authentication request is generated and posted, as
    # described here:
    #
    #   https://www.docs.verify.service.gov.uk/get-started/set-up-successful-verification-journey/#generate-an-authentication-request
    def new
      @verify_authentication_request = Verify::AuthenticationRequest.new(
        saml_request: "SAML_REQUEST",
        request_id: "REQUEST_ID",
        sso_location: "SSO_LOCATION"
      )
    end
  end
end
