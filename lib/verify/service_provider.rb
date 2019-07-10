module Verify
  # Interface for interacting with an instance of a Verify Service Provider.
  #
  # Make sure the VSP host is configured, for example:
  #
  #   Verify.vsp_host= "https://vsp.host:50300"
  class ServiceProvider
    def self.generate_request_url
      "#{Verify.vsp_host}/generate-request"
    end

    def self.translate_response_url
      "#{Verify.vsp_host}/translate-response"
    end

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
    # Raises Verify::ResponseError if the VSP responds with an error response.
    def generate_request
      uri = URI(self.class.generate_request_url)
      request = Net::HTTP::Post.new(uri, {})
      request.content_type = "application/json"
      response = Net::HTTP.start(uri.hostname, uri.port) { |http| http.request(request) }

      handle_response response.body
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
    # Raises Verify::ResponseError if the VSP responds with an error response.
    def translate_response(saml_response, request_id, level_of_assurance)
      uri = URI(self.class.translate_response_url)
      request = Net::HTTP::Post.new(uri)
      request.body = {"samlResponse" => saml_response, "requestId" => request_id, "levelOfAssurance" => level_of_assurance}.to_json
      request.content_type = "application/json"
      response = Net::HTTP.start(uri.hostname, uri.port) { |http| http.request(request) }

      handle_response response.body
    end

    private

    def handle_response(json_response)
      JSON.parse(json_response).tap do |parameters|
        raise ResponseError.new(parameters["message"], parameters["code"]) if parameters.key?("code")
      end
    end
  end
end
