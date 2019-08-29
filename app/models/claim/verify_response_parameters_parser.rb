class Claim
  class VerifyResponseParametersParser
    class MissingResponseAttribute < StandardError; end

    def initialize(response_parameters)
      @response_parameters = response_parameters
    end

    def gender
      {"MALE" => :male, "FEMALE" => :female}[verify_attributes.dig("gender", "value")]
    end

    def date_of_birth
      verify_attributes.fetch("datesOfBirth").first.fetch("value")
    end

    def first_name
      most_recent_verified("firstNames")
    end

    def surname
      most_recent_verified("surnames")
    end

    def middle_name
      most_recent_verified("middleNames", required: false)
    end

    def full_name
      [first_name, middle_name, surname].compact.join(" ")
    end

    def postcode
      most_recent_address&.fetch("postCode")
    end

    def address_line_1
      address_lines[0]
    end

    def address_line_2
      address_lines[1]
    end

    def address_line_3
      address_lines[2]
    end

    def address_line_4
      address_lines[3]
    end

    private

    def verify_attributes
      @response_parameters.fetch("attributes")
    end

    def most_recent_verified(attribute_name, required: true)
      raise MissingResponseAttribute, "No verified value found for #{attribute_name}" if required && no_verified_values?(attribute_name)

      verify_attributes.fetch(attribute_name)
        .select { |value| value["verified"] }
        .max_by { |value| Date.parse(value.fetch("from", Date.today.to_s)) }&.fetch("value")
    end

    def no_verified_values?(attribute_name)
      verify_attributes.fetch(attribute_name).none? { |value| value["verified"] }
    end

    def most_recent_address
      @most_recent_address ||= most_recent_verified("addresses", required: false)
    end

    def address_lines
      most_recent_address&.fetch("lines") || []
    end
  end
end
