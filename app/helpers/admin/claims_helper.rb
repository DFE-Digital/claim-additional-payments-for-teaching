module Admin
  module ClaimsHelper
    include ::ClaimsHelper

    def admin_eligibility_answers(eligibility)
      [].tap do |a|
        a << [t("student_loans.questions.admin.qts_award_year"), academic_years(eligibility.qts_award_year)]
        a << [t("student_loans.questions.admin.claim_school"), eligibility.claim_school_name]
        a << [t("questions.admin.current_school"), eligibility.current_school_name]
        a << [t("student_loans.questions.admin.subjects_taught"), subject_list(eligibility.subjects_taught)]
        a << [t("student_loans.questions.admin.had_leadership_position"), (eligibility.had_leadership_position? ? "Yes" : "No")]
        a << [t("student_loans.questions.admin.mostly_performed_leadership_duties"), (eligibility.mostly_performed_leadership_duties? ? "Yes" : "No")] if eligibility.had_leadership_position?
      end
    end

    def admin_identity_answers(claim)
      [
        [t("questions.admin.teacher_reference_number"), claim.teacher_reference_number],
        [t("questions.admin.national_insurance_number"), claim.national_insurance_number],
        [t("questions.admin.email_address"), claim.email_address],
      ]
    end
  end
end
