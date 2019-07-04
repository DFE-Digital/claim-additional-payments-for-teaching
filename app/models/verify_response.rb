class VerifyResponse
  include Rails.application.routes.url_helpers

  attr_reader :parameters, :scenario

  def initialize(parameters)
    @parameters = parameters
    @scenario = parameters["scenario"]
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

  def error_path
    return nil if verified?
    return failed_verify_authentications_path if scenario == "AUTHENTICATION_FAILED"
    return exited_verify_authentications_path if scenario == "NO_AUTHENTICATION"
    error_verify_authentications_path
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
