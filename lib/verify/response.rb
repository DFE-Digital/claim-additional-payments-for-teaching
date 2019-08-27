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

    def claim_parameters
      return {} unless verified?

      identity_paramteters.merge(
        verified_fields: verified_fields,
        verify_response: parameters
      )
    end

    def scenario
      @scenario ||= parameters["scenario"]
    end

    private

    def identity_paramteters
      @identity_paramteters ||= {
        full_name: full_name,
        address_line_1: address_line(1),
        address_line_2: address_line(2),
        address_line_3: address_line(3),
        address_line_4: address_line(4),
        postcode: postcode,
        date_of_birth: attributes.fetch("datesOfBirth").first.fetch("value"),
        payroll_gender: gender,
      }
    end

    def verified_fields
      identity_paramteters.reject { |k, v| v.blank? }.keys
    end

    def address
      @address ||= most_recent_verified_value("addresses", required: false)
    end

    def address_lines
      @address_lines ||= address.fetch("lines")
    end

    def address_line(line)
      address_lines[line - 1] unless address_missing?
    end

    def postcode
      address.fetch("postCode") unless address_missing?
    end

    def address_missing?
      address.nil?
    end

    def full_name
      first_name = most_recent_verified_value("firstNames")
      middle_name = most_recent_verified_value("middleNames", required: false)
      surname = most_recent_verified_value("surnames")

      [first_name, middle_name, surname].compact.join(" ")
    end

    def most_recent_verified_value(attribute_name, required: true)
      if required
        attrs = attributes.fetch(attribute_name)

        raise MissingResponseAttribute, "No values found for #{attribute_name}" if attrs.blank?
      else
        attrs = attributes.dig(attribute_name)

        return if attrs.blank?
      end

      verified_attributes = attrs.select { |attribute| attribute["verified"] }

      raise MissingResponseAttribute, "No verified values found for #{attribute_name}" if required && verified_attributes.empty?

      # If it exists, assume the first (and only) attribute without "from" is always the most recent.
      most_recent_verified_attribute = verified_attributes.find { |attribute| attribute["from"].nil? }
      most_recent_verified_attribute = verified_attributes.max_by { |attribute| Date.strptime(attribute["from"], "%Y-%m-%d") } if most_recent_verified_attribute.nil?

      if required
        raise MissingResponseAttribute, "No most recent verified value found for #{attribute_name}" if most_recent_verified_attribute.nil?

        return most_recent_verified_attribute.fetch("value")
      else
        return most_recent_verified_attribute&.fetch("value")
      end
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
