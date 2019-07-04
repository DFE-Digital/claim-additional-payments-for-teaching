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
      verify_authentication_response = Verify::ServiceProvider.new.translate_response(params["SAMLResponse"], session[:verify_request_id], "LEVEL_2")
      @response = VerifyResponse.new(verify_authentication_response)

      if @response.verified?
        current_claim.update!(@response.claim_parameters)
        redirect_to claim_path("teacher-reference-number")
      else
        redirect_to @response.error_path
      end
    end

    def failed
    end

    def exited
    end

    def error
      render :error, head: :bad_request
    end
  end
end
