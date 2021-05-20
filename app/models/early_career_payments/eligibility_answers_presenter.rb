module EarlyCareerPayments
  class EligibilityAnswersPresenter
    include ActionView::Helpers::TranslationHelper

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
        a << nqt_in_academic_year_after_itt
        a << current_school
        a << employed_as_supply_teacher
        a << has_entire_term_contract if eligibility.employed_as_supply_teacher?
        a << employed_directly if eligibility.employed_as_supply_teacher?
        a << subject_to_formal_performance_action
        a << subject_to_disciplinary_action
        a << pgitt_or_ugitt_course
        a << eligible_itt_subject
        a << teaching_subject_now
        a << itt_academic_year
      end
    end

    private

    def has_entire_term_contract
      [
        translate("early_career_payments.questions.has_entire_term_contract"),
        (eligibility.has_entire_term_contract? ? "Yes" : "No"),
        "entire-term-contract"
      ]
    end

    def nqt_in_academic_year_after_itt
      [
        translate("early_career_payments.questions.nqt_in_academic_year_after_itt"),
        (eligibility.nqt_in_academic_year_after_itt? ? "Yes" : "No"),
        "nqt-in-academic-year-after-itt"
      ]
    end

    def current_school
      [
        translate("questions.current_school"),
        eligibility.current_school_name,
        "current-school"
      ]
    end

    def employed_as_supply_teacher
      [
        translate("early_career_payments.questions.employed_as_supply_teacher"),
        (eligibility.employed_as_supply_teacher? ? "Yes" : "No"),
        "supply-teacher"
      ]
    end

    def employed_directly
      [
        translate("early_career_payments.questions.employed_directly"),
        (eligibility.employed_directly? ? "Yes" : "No"),
        "employed-directly"
      ]
    end

    def subject_to_formal_performance_action
      [
        translate("early_career_payments.questions.formal_performance_action"),
        (eligibility.subject_to_formal_performance_action? ? "Yes" : "No"),
        "formal-performance-action"
      ]
    end

    def subject_to_disciplinary_action
      [
        translate("early_career_payments.questions.disciplinary_action"),
        (eligibility.subject_to_disciplinary_action? ? "Yes" : "No"),
        "disciplinary-action"
      ]
    end

    def pgitt_or_ugitt_course
      [
        translate("early_career_payments.questions.postgraduate_itt_or_undergraduate_itt_course"),
        translate("early_career_payments.answers.pgitt_or_ugitt_course.#{eligibility.pgitt_or_ugitt_course}"),
        "postgraduate-itt-or-undergraduate-itt-course"
      ]
    end

    def eligible_itt_subject
      [
        translate("early_career_payments.questions.eligible_itt_subject", ug_or_pg: eligibility.pgitt_or_ugitt_course),
        translate("early_career_payments.answers.eligible_itt_subject.#{eligibility.eligible_itt_subject}"),
        "eligible-itt-subject"
      ]
    end

    def teaching_subject_now
      [
        translate("early_career_payments.questions.teaching_subject_now", eligible_itt_subject: eligibility.eligible_itt_subject),
        (eligibility.teaching_subject_now? ? "Yes" : "No"),
        "teaching-subject-now"
      ]
    end

    def itt_academic_year
      [
        translate(
          "early_career_payments.questions.itt_academic_year",
          start_or_complete: (eligibility.pgitt_or_ugitt_course == "postgraduate" ? "start" : "complete"),
          ug_or_pg: eligibility.pgitt_or_ugitt_course
        ),
        eligibility.itt_academic_year&.dasherize&.gsub("-", " - "),
        "itt-year"
      ]
    end
  end
end
