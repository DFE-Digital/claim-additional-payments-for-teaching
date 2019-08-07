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

      identity_paramteters.merge(
        verified_fields: verified_fields
      )
    end

    def scenario
      @scenario ||= parameters["scenario"]
    end

    private

    def identity_paramteters
      @identity_paramteters ||= {
        full_name: full_name,
        address_line_1: address_lines[0],
        address_line_2: address_lines[1],
        address_line_3: address_lines[2],
        postcode: address.fetch("postCode"),
        date_of_birth: attributes.fetch("datesOfBirth").first.fetch("value"),
        payroll_gender: gender,
      }
    end

    def verified_fields
      identity_paramteters.reject { |k, v| v.blank? }.keys
    end

    def address
      @address ||= most_recent_verified_value(attributes.dig("addresses"))
    end

    def address_lines
      @address_lines ||= address.fetch("lines")
    end

    def full_name
      first_name = most_recent_verified_value(attributes.fetch("firstNames"))
      middle_name = most_recent_verified_value(attributes.fetch("middleNames"))
      surname = most_recent_verified_value(attributes.fetch("surnames"))

      [first_name, middle_name, surname].compact.join(" ")
    end

    def most_recent_verified_value(attributes)
      return if attributes.empty?

      attributes.sort_by { |attribute| attribute["from"].present? ? Date.strptime(attribute["from"], "%Y-%m-%d") : 0 }
        .reverse
        .find { |attribute| attribute["verified"] }
        .fetch("value")
    end

    def gender
      gender = attributes.dig("gender", "value")

      return :female if gender == "FEMALE"
      return :male if gender == "MALE"
    end

    def attributes
      @attributes ||= parameters.fetch("attributes")
    end
  end
end
