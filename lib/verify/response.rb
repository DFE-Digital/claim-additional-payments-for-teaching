module Verify
  # Represents a Response from a Verify authentication attempt.
  #
  # Use by calling Verify::Response.translate to translate a SAML response using
  # the Verify Service Provider, for example:
  #
  #   Verify::Response.translate(saml_response: "SOME SAML", request_id: "REQUEST_ID", level_of_assurance: "LEVEL_2")
  #
  class Response
    attr_reader :parameters

    def initialize(parameters)
      @parameters = parameters
    end

    def self.translate(saml_response:, request_id:, level_of_assurance:)
      parameters = Verify::ServiceProvider.new.translate_response(saml_response, request_id, level_of_assurance)
      new(parameters)
    end

    def verified?
      scenario == "IDENTITY_VERIFIED"
    end

    def claim_parameters
      return {} unless verified?

      {
        full_name: full_name,
        address_line_1: address_lines[0],
        address_line_2: address_lines[1],
        address_line_3: address_lines[2],
        postcode: address.fetch("postCode"),
        date_of_birth: parameters.fetch("attributes").fetch("datesOfBirth").first.fetch("value"),
      }
    end

    def scenario
      @scenario ||= parameters["scenario"]
    end

    def error
      return nil if verified?

      scenario.nil? ? "error" : scenario.downcase
    end

    private

    def address
      @address ||= parameters.fetch("attributes").fetch("addresses").first.fetch("value")
    end

    def address_lines
      @address_lines ||= address.fetch("lines")
    end

    def full_name
      first_name = parameters.fetch("attributes").fetch("firstNames").first.fetch("value")
      middle_name = parameters.fetch("attributes").fetch("middleNames").first.fetch("value")
      surname = parameters.fetch("attributes").fetch("surnames").first.fetch("value")

      [first_name, middle_name, surname].join(" ")
    end
  end
end
