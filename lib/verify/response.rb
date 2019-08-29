module Verify
  # Represents a Response from a Verify authentication attempt.
  #
  # Use by calling Verify::Response.translate to translate a SAML response using
  # the Verify Service Provider, for example:
  #
  #   Verify::Response.translate(saml_response: "SOME SAML", request_id: "REQUEST_ID", level_of_assurance: "LEVEL_2")
  #
  class Response
    class MissingResponseAttribute < StandardError; end
    attr_reader :parameters

    def initialize(parameters)
      @parameters = parameters
    end

    def self.translate(saml_response:, request_id:, level_of_assurance:)
      parameters = Verify::ServiceProvider.new.translate_response(saml_response, request_id, level_of_assurance)
      new(parameters)
    end

    def verified?
      scenario == Verify::IDENTITY_VERIFIED_SCENARIO
    end

    def scenario
      @scenario ||= parameters["scenario"]
    end
  end
end
