# frozen_string_literal: true

class Claim
  # Used to convert the parameters from a successful Verify::Response into an
  # attributes Hash that can be used to update a claim. For example,
  #
  #   Claim::VerifyResponseParametersParser.new(verify_response.parameters).attributes
  #   => { first_name: "Margaret", last_name: "Hamilton", date_of_birth: "1936-08-17", ...}
  #
  # As well as keys for the personal information of the user (name, address,
  # etc) the returned Hash includes an additional `govuk_verify_fields` key,
  # which are the keys for the attributes that have come back in the Verify
  # response. Recording these allows us to determine which attributes came
  # from Verify and therefore should not be editable by the user.
  #
  class VerifyResponseParametersParser
    class MissingResponseAttribute < StandardError; end

    def initialize(response_parameters)
      @response_parameters = response_parameters
    end

    def attributes
      identity_attributes.merge(govuk_verify_fields: govuk_verify_fields)
    end

    def gender
      {"MALE" => :male, "FEMALE" => :female}[verify_attributes.dig("gender", "value")]
    end

    def date_of_birth
      verify_attributes.fetch("datesOfBirth").first.fetch("value")
    end

    def first_name
      most_recent_value("firstNames")
    end

    def surname
      most_recent_value("surnames")
    end

    def middle_name
      most_recent_value("middleNames", required: false)
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

    def most_recent_value(attribute_name, required: true, verified: true)
      raise MissingResponseAttribute, "No verified value found for #{attribute_name}" if required && verified && no_verified_values?(attribute_name)

      sorted_by_date = verify_attributes.fetch(attribute_name)
        .sort_by { |value| Date.parse(value.fetch("from", Date.today.to_s)) }

      sorted_by_date.select! { |value| value["verified"] } if verified

      sorted_by_date.last&.fetch("value")
    end

    def no_verified_values?(attribute_name)
      verify_attributes.fetch(attribute_name).none? { |value| value["verified"] }
    end

    def most_recent_address
      @most_recent_address ||= most_recent_value("addresses", required: false, verified: false)
    end

    def address_lines
      most_recent_address&.fetch("lines") || []
    end

    def identity_attributes
      @identity_attributes ||= {
        first_name: first_name,
        middle_name: middle_name,
        surname: surname,
        date_of_birth: date_of_birth,
        payroll_gender: gender,
        address_line_1: address_line_1,
        address_line_2: address_line_2,
        address_line_3: address_line_3,
        address_line_4: address_line_4,
        postcode: postcode
      }.compact
    end

    def govuk_verify_fields
      identity_attributes.keys
    end
  end
end
