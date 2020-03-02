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
        a << teaching_maths_or_physics
        a << current_school
        a << initial_teacher_training_subject
        a << initial_teacher_training_subject_specialism if eligibility.initial_teacher_training_subject_specialism.present?
        a << has_uk_maths_or_physics_degree if eligibility.has_uk_maths_or_physics_degree.present?
        a << qts_award_year
        a << employed_as_supply_teacher
        a << has_entire_term_contract if eligibility.employed_as_supply_teacher?
        a << employed_directly if eligibility.employed_as_supply_teacher?
        a << disciplinary_action
        a << formal_performance_action
      end
    end

    private

    def teaching_maths_or_physics
      [
        I18n.t("maths_and_physics.questions.teaching_maths_or_physics"),
        (eligibility.teaching_maths_or_physics? ? "Yes" : "No"),
        "teaching-maths-or-physics"
      ]
    end

    def current_school
      [
        I18n.t("questions.current_school"),
        eligibility.current_school_name,
        "current-school"
      ]
    end

    def initial_teacher_training_subject
      [
        I18n.t("maths_and_physics.questions.initial_teacher_training_subject"),
        I18n.t("maths_and_physics.answers.initial_teacher_training_subject.#{eligibility.initial_teacher_training_subject}"),
        "initial-teacher-training-subject"
      ]
    end

    def initial_teacher_training_subject_specialism
      [
        I18n.t("maths_and_physics.questions.initial_teacher_training_subject_specialism"),
        I18n.t("maths_and_physics.answers.initial_teacher_training_subject_specialism.#{eligibility.initial_teacher_training_subject_specialism}"),
        "initial-teacher-training-subject-specialism"
      ]
    end

    def has_uk_maths_or_physics_degree
      [
        I18n.t("maths_and_physics.questions.has_uk_maths_or_physics_degree"),
        degree_answer,
        "has-uk-maths-or-physics-degree"
      ]
    end

    def qts_award_year
      [
        I18n.t("questions.qts_award_year"),
        eligibility.qts_award_year_answer,
        "qts-year"
      ]
    end

    def employed_as_supply_teacher
      [
        I18n.t("maths_and_physics.questions.employed_as_supply_teacher"),
        (eligibility.employed_as_supply_teacher? ? "Yes" : "No"),
        "supply-teacher"
      ]
    end

    def has_entire_term_contract
      [
        I18n.t("maths_and_physics.questions.has_entire_term_contract"),
        (eligibility.has_entire_term_contract? ? "Yes" : "No"),
        "entire-term-contract"
      ]
    end

    def employed_directly
      [
        I18n.t("maths_and_physics.questions.employed_directly"),
        I18n.t("maths_and_physics.answers.employed_directly.#{eligibility.employed_directly? ? "yes" : "no"}"),
        "employed-directly"
      ]
    end

    def disciplinary_action
      [
        I18n.t("maths_and_physics.questions.disciplinary_action"),
        (eligibility.subject_to_disciplinary_action? ? "Yes" : "No"),
        "disciplinary-action"
      ]
    end

    def formal_performance_action
      [
        I18n.t("maths_and_physics.questions.formal_performance_action"),
        (eligibility.subject_to_formal_performance_action? ? "Yes" : "No"),
        "formal-performance-action"
      ]
    end

    def degree_answer
      case eligibility.has_uk_maths_or_physics_degree
      when "yes" then "Yes"
      when "no" then "No"
      else I18n.t("maths_and_physics.answers.has_uk_maths_or_physics_degree.#{eligibility.has_uk_maths_or_physics_degree}")
      end
    end
  end
end
