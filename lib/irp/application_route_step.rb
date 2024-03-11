class ApplicationRouteStep < BaseStep
  ROUTE_KEY = "application-route".freeze

  REQUIRED_FIELDS = %i[application_route].freeze

  VALID_ANSWERS_OPTIONS = %w[salaried_trainee teacher other].freeze

  def configure_step
    @question = t("steps.application_route.question")
    @question_hint = t("steps.application_route.hint")
    @question_type = :radio
    @valid_answers = [
      Answer.new(
        value: :teacher,
        label: t("steps.application_route.answers.teacher.text"),
      ),
      Answer.new(
        value: :salaried_trainee,
        label: t("steps.application_route.answers.salaried_trainee.text"),
        hint: t("steps.application_route.answers.salaried_trainee.hint"),
      ),
      Answer.new(
        value: :other,
        label: t("steps.application_route.answers.other.text"),
      ),
    ]
  end
end
