module StudentLoans
  class EligibilityAnswersPresenter
    include StudentLoansHelper
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
        a << qts_award_year
        a << claim_school
        a << current_school
        a << subjects_taught
        a << leadership_position
        a << mostly_performed_leadership_duties if eligibility.had_leadership_position?
        a << student_loan_amount
      end
    end

    private

    def qts_award_year
      [
        I18n.t("questions.qts_award_year"),
        eligibility.qts_award_year_answer,
        "qts-year"
      ]
    end

    def claim_school
      [
        claim_school_question,
        eligibility.claim_school_name,
        "claim-school"
      ]
    end

    def current_school
      [
        I18n.t("questions.current_school"),
        eligibility.current_school_name,
        "still-teaching"
      ]
    end

    def subjects_taught
      [
        subjects_taught_question(school_name: eligibility.claim_school_name),
        subject_list(eligibility.subjects_taught),
        "subjects-taught"
      ]
    end

    def leadership_position
      [
        leadership_position_question,
        (eligibility.had_leadership_position? ? "Yes" : "No"),
        "leadership-position"
      ]
    end

    def mostly_performed_leadership_duties
      [
        I18n.t("student_loans.questions.mostly_performed_leadership_duties"),
        (eligibility.mostly_performed_leadership_duties? ? "Yes" : "No"),
        "mostly-performed-leadership-duties"
      ]
    end

    def student_loan_amount
      [
        I18n.t("student_loans.questions.student_loan_amount"),
        number_to_currency(eligibility.student_loan_repayment_amount),
        "student-loan-amount"
      ]
    end
  end
end
