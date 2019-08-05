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
      Rollbar.debug("Verify::Response", parameters: parameters)
    end

    def self.translate(saml_response:, request_id:, level_of_assurance:)
      parameters = Verify::ServiceProvider.new.translate_response(saml_response, request_id, level_of_assurance)
      new(parameters)
    end

    def verified?
      scenario == Verify::IDENTITY_VERIFIED_SCENARIO
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

    private

    def address
      @address ||= most_recent_verified_value(parameters.fetch("attributes").fetch("addresses"))
    end

    def address_lines
      @address_lines ||= address.fetch("lines")
    end

    def full_name
      first_name = most_recent_verified_value(parameters.fetch("attributes").fetch("firstNames"))
      middle_name = most_recent_verified_value(parameters.fetch("attributes").fetch("middleNames"))
      surname = most_recent_verified_value(parameters.fetch("attributes").fetch("surnames"))

      [first_name, middle_name, surname].join(" ")
    end

    def most_recent_verified_value(attributes)
      attributes.sort_by { |attribute| Date.strptime(attribute["to"], "%Y-%m-%d") }
        .reverse
        .find { |attribute| attribute["verified"] }
        .fetch("value")
    end
  end
end
