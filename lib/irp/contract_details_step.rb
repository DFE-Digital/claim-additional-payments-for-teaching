class ContractDetailsStep < BaseStep
  ROUTE_KEY = "contract-details".freeze

  REQUIRED_FIELDS = %i[one_year].freeze

  VALID_ANSWERS_OPTIONS = %w[true false].freeze

  def configure_step
    @question = t("steps.contract_details.question")
    @question_hint = t("steps.contract_details.hint")
    @question_type = :radio
    @valid_answers = [
      Answer.new(value: true, label: t("steps.contract_details.answers.yes.text")),
      Answer.new(value: false, label: t("steps.contract_details.answers.no.text")),
    ]
  end
end
