module MathsAndPhysics
  class EligibilityAdminAnswersPresenter
    include Admin::PresenterMethods

    attr_reader :eligibility

    def initialize(eligibility)
      @eligibility = eligibility
    end

    # Formats the eligibility as a list of questions and answers.
    # Suitable for playback to the service operators for them to review
    # the claim.
    #
    # Returns an array. Each element of this an array is an array of two
    # elements:
    # [0]: short question text;
    # [1]: answer text;
    def answers
      [].tap do |a|
        a << [I18n.t("maths_and_physics.admin.teaching_maths_or_physics"), (eligibility.teaching_maths_or_physics? ? "Yes" : "No")]
        a << [I18n.t("admin.current_school"), display_school(eligibility.current_school)]
        a << [I18n.t("maths_and_physics.admin.initial_teacher_training_subject"), I18n.t("maths_and_physics.answers.initial_teacher_training_subject.#{eligibility.initial_teacher_training_subject}")]
        a << [I18n.t("maths_and_physics.admin.initial_teacher_training_subject_specialism"), I18n.t("maths_and_physics.answers.initial_teacher_training_subject_specialism.#{eligibility.initial_teacher_training_subject_specialism}")] if eligibility.initial_teacher_training_subject_specialism.present?
        a << [I18n.t("maths_and_physics.admin.has_uk_maths_or_physics_degree"), degree_answer] if eligibility.has_uk_maths_or_physics_degree.present?
        a << [I18n.t("admin.qts_award_year"), I18n.t("maths_and_physics.questions.qts_award_years.#{eligibility.qts_award_year}")]
        a << [I18n.t("maths_and_physics.admin.employed_as_supply_teacher"), (eligibility.employed_as_supply_teacher? ? "Yes" : "No")]
        a << [I18n.t("maths_and_physics.admin.has_entire_term_contract"), (eligibility.has_entire_term_contract? ? "Yes" : "No")] unless eligibility.has_entire_term_contract.nil?
        a << [I18n.t("maths_and_physics.admin.employed_directly"), I18n.t("maths_and_physics.answers.employed_directly.#{eligibility.employed_directly? ? "yes" : "no"}")] unless eligibility.employed_directly.nil?
        a << [I18n.t("maths_and_physics.admin.disciplinary_action"), (eligibility.subject_to_disciplinary_action? ? "Yes" : "No")]
        a << [I18n.t("maths_and_physics.admin.formal_performance_action"), (eligibility.subject_to_formal_performance_action? ? "Yes" : "No")]
      end
    end

    private

    def degree_answer
      case eligibility.has_uk_maths_or_physics_degree
      when "yes" then "Yes"
      when "no" then "No"
      else I18n.t("maths_and_physics.answers.has_uk_maths_or_physics_degree.#{eligibility.has_uk_maths_or_physics_degree}")
      end
    end
  end
end
