class TraineeDetailsStep < BaseStep
  ROUTE_KEY = "trainee-details".freeze

  REQUIRED_FIELDS = %i[state_funded_secondary_school].freeze

  VALID_ANSWERS_OPTIONS = %w[true false].freeze

  def configure_step
    @question      = t("steps.trainee_details.question")
    @question_hint = t("steps.trainee_details.hint")
    @question_type = :radio
    @valid_answers = [
      Answer.new(value: true, label: "Yes"),
      Answer.new(value: false, label: "No"),
    ]
  end
end
