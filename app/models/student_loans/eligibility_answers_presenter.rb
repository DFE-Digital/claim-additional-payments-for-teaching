module StudentLoans
  class EligibilityAnswersPresenter
    include StudentLoans::PresenterMethods
    include ActiveSupport::NumberHelper

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
        a << [I18n.t("questions.qts_award_year"), I18n.t("student_loans.questions.qts_award_years.#{eligibility.qts_award_year}"), "qts-year"]
        a << [I18n.t("student_loans.questions.claim_school"), eligibility.claim_school_name, "claim-school"]
        a << [I18n.t("questions.current_school"), eligibility.current_school_name, "still-teaching"]
        a << [I18n.t("student_loans.questions.subjects_taught", school: eligibility.claim_school_name), subject_list(eligibility.subjects_taught), "subjects-taught"]
        a << [I18n.t("student_loans.questions.leadership_position"), (eligibility.had_leadership_position? ? "Yes" : "No"), "leadership-position"]
        a << [I18n.t("student_loans.questions.mostly_performed_leadership_duties"), (eligibility.mostly_performed_leadership_duties? ? "Yes" : "No"), "mostly-performed-leadership-duties"] if eligibility.had_leadership_position?
        a << [I18n.t("student_loans.questions.student_loan_amount"), number_to_currency(eligibility.student_loan_repayment_amount), "student-loan-amount"]
      end
    end
  end
end
