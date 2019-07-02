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
      current_claim.update!(claim_parameters_from_response(verify_authentication_response))
      redirect_to claim_path("teacher-reference-number")
    end

    private

    def claim_parameters_from_response(response)
      {
        full_name: full_name_from_response(response),
        address_line_1: response.fetch("attributes").fetch("addresses").first.fetch("value").fetch("lines")[0],
        address_line_2: response.fetch("attributes").fetch("addresses").first.fetch("value").fetch("lines")[1],
        address_line_3: response.fetch("attributes").fetch("addresses").first.fetch("value").fetch("lines")[2],
        postcode: response.fetch("attributes").fetch("addresses").first.fetch("value").fetch("postCode"),
        date_of_birth: response.fetch("attributes").fetch("datesOfBirth").first.fetch("value"),
      }
    end

    def full_name_from_response(response)
      first_name = response.fetch("attributes").fetch("firstNames").first.fetch("value")
      middle_name = response.fetch("attributes").fetch("middleNames").first.fetch("value")
      surname = response.fetch("attributes").fetch("surnames").first.fetch("value")

      [first_name, middle_name, surname].join(" ")
    end
  end
end
