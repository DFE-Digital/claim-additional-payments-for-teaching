module Verify
  class ServiceProvider
    GENERATE_REQUEST_URL = "http://localhost:50300/generate-request".freeze
    TRANSLATE_RESPONSE_URL = "http://localhost:50300/translate-response".freeze

    # Makes a request to the Verify Service Provider to generate an
    # authentication request, as described here:
    #
    #   https://www.docs.verify.service.gov.uk/get-started/set-up-successful-verification-journey/#generate-an-authentication-request
    #
    # The authentication request is used to start the identity assurance process
    # with Verify.
    #
    # Returns the authentication request as a Hash, for example:
    #
    #   {
    #     "samlRequest" => "PD94bWwgdmVyc2lvbj0iMS4wIiBlb...",
    #     "requestId" => "_f43aa274-9395-45dd-aaef-25f56fe",
    #     "ssoLocation" => "https://compliance-tool-reference.ida.digital.cabinet-office.gov.uk/SAML2/SSO"
    #   }
    #
    def generate_request
      uri = URI(GENERATE_REQUEST_URL)
      request = Net::HTTP::Post.new(uri, {})
      request.content_type = "application/json"
      response = Net::HTTP.start(uri.hostname, uri.port) { |http| http.request(request) }

      JSON.parse(response.body)
    end

    # Makes a request to the Verify Service Provider to translate a SAML
    # response returned by Verify, as described here:
    #
    #   https://www.docs.verify.service.gov.uk/get-started/set-up-successful-verification-journey/#request-to-translate-the-saml-response
    #
    # The SAML response is the payload representing the result of the Verify
    # identity assurance attempt by the user.
    #
    # Returns the translated response as a Hash, for example:
    #
    #   {
    #       "scenario" => "IDENTITY_VERIFIED",
    #       "pid" => "etikgj3ewowe",
    #       "levelOfAssurance" => "LEVEL_2",
    #       "attributes" => {...}
    #   }
    #
    def translate_response(saml_response, request_id, level_of_assurance)
      uri = URI(TRANSLATE_RESPONSE_URL)
      request = Net::HTTP::Post.new(uri)
      request.body = {"samlResponse" => saml_response, "requestId" => request_id, "levelOfAssurance" => level_of_assurance}.to_json
      request.content_type = "application/json"
      response = Net::HTTP.start(uri.hostname, uri.port) { |http| http.request(request) }

      JSON.parse(response.body)
    end
  end
end
