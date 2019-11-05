module Verify
  class AuthenticationsController < BasePublicController
    CLAIM_TIMEOUT_LENGTH_IN_MINUTES = 90

    include PartOfClaimJourney

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
      report_redacted_response
      if @response.verified?
        parser = Claim::VerifyResponseParametersParser.new(@response.parameters)
        current_claim.update!(parser.attributes)
        redirect_to claim_url("verified")
      else
        current_claim.update!(verify_response: @response.parameters)
        redirect_to verify_path_for_response_scenario(@response.scenario)
      end
    end

    def failed
    end

    def no_auth
    end

    private

    def verify_path_for_response_scenario(scenario)
      case scenario
      when Verify::AUTHENTICATION_FAILED_SCENARIO
        failed_verify_authentications_path
      when Verify::NO_AUTHENTICATION_SCENARIO
        no_auth_verify_authentications_path
      end
    end

    def report_redacted_response
      redacted_response = Verify::RedactedResponse.new(@response.parameters)
      Rollbar.debug("Verify::RedactedResponse", parameters: redacted_response.parameters)
    end
  end
end
