module Verify
  class ServiceProvider
    GENERATE_REQUEST_URL = "http://localhost:50300/generate-request".freeze

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
  end
end
