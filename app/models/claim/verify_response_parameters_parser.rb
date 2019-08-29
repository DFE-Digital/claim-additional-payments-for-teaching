class Claim
  class VerifyResponseParametersParser
    def initialize(response_parameters)
      @response_parameters = response_parameters
    end

    def gender
      {"MALE" => :male, "FEMALE" => :female}[attributes.dig("gender", "value")]
    end

    def date_of_birth
      attributes.fetch("datesOfBirth").first.fetch("value")
    end

    private

    def attributes
      @response_parameters.fetch("attributes")
    end
  end
end
