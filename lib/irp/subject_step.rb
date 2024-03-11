class SubjectStep < BaseStep
  ROUTE_KEY = "subject".freeze

  REQUIRED_FIELDS = %i[subject].freeze

  VALID_ANSWERS_OPTIONS = %w[combined_with_physics physics languages other].freeze

  def configure_step
    @question      = t("steps.subject.question.#{form.application_route}")
    @question_hint = t("steps.subject.hint.#{form.application_route}")
    @question_type = :radio
    extra_answer   = Answer.new(
      value: :combined_with_physics,
      label: t("steps.subject.answers.combined_with_physics.text"),
    )
    @valid_answers = [
      Answer.new(
        value: :physics,
        label: t("steps.subject.answers.physics.text"),
      ),
      Answer.new(
        value: :languages,
        label: t("steps.subject.answers.languages.text"),
      ),
      Answer.new(
        value: :other,
        label: t("steps.subject.answers.other.text"),
      ),
    ].tap { _1.insert(1, extra_answer) if form.teacher_route? }
  end
end
