module Verify
  class AuthenticationsController < ApplicationController
    before_action :send_unstarted_claiments_to_the_start
    skip_before_action :verify_authenticity_token, only: [:create]

    # Page where a new Verify authentication request is generated and posted, as
    # described here:
    #
    #   https://www.docs.verify.service.gov.uk/get-started/set-up-successful-verification-journey/#generate-an-authentication-request
    def new
      @verify_authentication_request = Verify::AuthenticationRequest.generate
      session[:verify_request_id] = @verify_authentication_request.request_id
    end

    # Callback where Verify will POST the SAML response for the authentication
    # attempt, as described here:
    #
    #   https://www.docs.verify.service.gov.uk/get-started/set-up-successful-verification-journey/#handle-a-response
    def create
      @response = Verify::Response.translate(saml_response: params["SAMLResponse"], request_id: session[:verify_request_id], level_of_assurance: "LEVEL_2")

      if @response.verified?
        current_claim.update!(@response.claim_parameters)
        redirect_to claim_path("teacher-reference-number")
      else
        render "failure"
      end
    end
  end
end
