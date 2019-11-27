module MathsAndPhysics
  class EligibilityAnswersPresenter
    attr_reader :eligibility

    def initialize(eligibility)
      @eligibility = eligibility
    end

    # Formats the eligibility as a list of questions and answers, each
    # accompanied by a slug for changing the answer. Suitable for playback to
    # the claimant for them to review on the check-your-answers page.
    #
    # Returns an array. Each element of this an array is an array of three
    # elements:
    # [0]: question text;
    # [1]: answer text;
    # [2]: slug for changing the answer.
    def answers
      [].tap do |a|
        a << [I18n.t("maths_and_physics.questions.teaching_maths_or_physics"), (eligibility.teaching_maths_or_physics? ? "Yes" : "No"), "teaching-maths-or-physics"]
        a << [I18n.t("questions.current_school"), eligibility.current_school_name, "current-school"]
        a << [I18n.t("maths_and_physics.questions.initial_teacher_training_specialised_in_maths_or_physics"), (eligibility.initial_teacher_training_specialised_in_maths_or_physics? ? "Yes" : "No"), "initial-teacher-training-specialised-in-maths-or-physics"]
        a << [I18n.t("maths_and_physics.questions.initial_teacher_training_subject"), I18n.t("maths_and_physics.answers.initial_teacher_training_subject.#{eligibility.initial_teacher_training_subject}"), "initial-teacher-training-subject"]
        a << [I18n.t("maths_and_physics.questions.has_uk_maths_or_physics_degree"), degree_answer, "has-uk-maths-or-physics-degree"] unless eligibility.initial_teacher_training_specialised_in_maths_or_physics?
        a << [I18n.t("questions.qts_award_year"), I18n.t("maths_and_physics.questions.qts_award_years.#{eligibility.qts_award_year}"), "qts-year"]
        a << [I18n.t("maths_and_physics.questions.employed_as_supply_teacher"), (eligibility.employed_as_supply_teacher? ? "Yes" : "No"), "supply-teacher"]
        a << [I18n.t("maths_and_physics.questions.has_entire_term_contract"), (eligibility.has_entire_term_contract? ? "Yes" : "No"), "entire-term-contract"] if eligibility.employed_as_supply_teacher?
        a << [I18n.t("maths_and_physics.questions.employed_directly"), I18n.t("maths_and_physics.answers.employed_directly.#{eligibility.employed_directly? ? "yes" : "no"}"), "employed-directly"] if eligibility.employed_as_supply_teacher?
        a << [I18n.t("maths_and_physics.questions.disciplinary_action"), (eligibility.subject_to_disciplinary_action? ? "Yes" : "No"), "disciplinary-action"]
        a << [I18n.t("maths_and_physics.questions.formal_performance_action"), (eligibility.subject_to_formal_performance_action? ? "Yes" : "No"), "formal-performance-action"]
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
