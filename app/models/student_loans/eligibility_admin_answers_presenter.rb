module StudentLoans
  class EligibilityAdminAnswersPresenter
    include PresenterMethods
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
        a << [I18n.t("admin.qts_award_year"), I18n.t("student_loans.questions.qts_award_years.#{eligibility.qts_award_year}")]
        a << [I18n.t("student_loans.admin.claim_school"), display_school(eligibility.claim_school)]
        a << [I18n.t("admin.current_school"), display_school(eligibility.current_school)]
        a << [I18n.t("student_loans.admin.subjects_taught"), subject_list(eligibility.subjects_taught)]
        a << [I18n.t("student_loans.admin.had_leadership_position"), (eligibility.had_leadership_position? ? "Yes" : "No")]
        a << [I18n.t("student_loans.admin.mostly_performed_leadership_duties"), (eligibility.mostly_performed_leadership_duties? ? "Yes" : "No")] if eligibility.had_leadership_position?
      end
    end
  end
end
