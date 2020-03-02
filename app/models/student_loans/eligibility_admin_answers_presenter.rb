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
        a << qts_award_year
        a << claim_school
        a << current_school
        a << subjects_taught
        a << had_leadership_position
        a << mostly_performed_leadership_duties if eligibility.had_leadership_position?
      end
    end

    private

    def qts_award_year
      [
        I18n.t("admin.qts_award_year"),
        eligibility.qts_award_year_answer
      ]
    end

    def claim_school
      [
        I18n.t("student_loans.admin.claim_school"),
        display_school(eligibility.claim_school)
      ]
    end

    def current_school
      [
        I18n.t("admin.current_school"),
        display_school(eligibility.current_school)
      ]
    end

    def subjects_taught
      [
        I18n.t("student_loans.admin.subjects_taught"),
        subject_list(eligibility.subjects_taught)
      ]
    end

    def had_leadership_position
      [
        I18n.t("student_loans.admin.had_leadership_position"),
        (eligibility.had_leadership_position? ? "Yes" : "No")
      ]
    end

    def mostly_performed_leadership_duties
      [
        I18n.t("student_loans.admin.mostly_performed_leadership_duties"),
        (eligibility.mostly_performed_leadership_duties? ? "Yes" : "No")
      ]
    end
  end
end
