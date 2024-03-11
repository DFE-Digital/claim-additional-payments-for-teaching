class VisaStep < BaseStep
  ROUTE_KEY = "visa".freeze

  REQUIRED_FIELDS = %i[visa_type].freeze

  VALID_ANSWERS_OPTIONS = [
    "Afghan Relocations and Assistance Policy",
    "Afghan citizens resettlement scheme",
    "British National (Overseas) visa",
    "Family visa",
    "High Potential Individual visa",
    "India Young Professionals Scheme visa",
    "Skilled worker visa",
    "UK Ancestry visa",
    "Ukraine Family Scheme visa",
    "Ukraine Sponsorship Scheme",
    "Youth Mobility Scheme",
    "Other",
  ].freeze

  def configure_step
    @question      = t("steps.visa.question")
    @question_type = :select
    @valid_answers = VALID_ANSWERS_OPTIONS.map { Answer.new(value: _1, label: _1) }
  end
end
