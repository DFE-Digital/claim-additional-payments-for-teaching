module Admin
  module ClaimsHelper
    include ::ClaimsHelper

    def admin_eligibility_answers(eligibility)
      [].tap do |a|
        a << [t("student_loans.questions.admin.qts_award_year"), academic_years(eligibility.qts_award_year)]
        a << [t("student_loans.questions.admin.claim_school"), link_to_school(eligibility.claim_school)]
        a << [t("questions.admin.current_school"), link_to_school(eligibility.current_school)]
        a << [t("student_loans.questions.admin.subjects_taught"), subject_list(eligibility.subjects_taught)]
        a << [t("student_loans.questions.admin.had_leadership_position"), (eligibility.had_leadership_position? ? "Yes" : "No")]
        a << [t("student_loans.questions.admin.mostly_performed_leadership_duties"), (eligibility.mostly_performed_leadership_duties? ? "Yes" : "No")] if eligibility.had_leadership_position?
      end
    end

    def admin_personal_details(claim)
      [
        [t("questions.admin.teacher_reference_number"), claim.teacher_reference_number],
        [t("verified_fields.full_name").capitalize, claim.full_name],
        [t("questions.admin.national_insurance_number"), claim.national_insurance_number],
        [t("verified_fields.date_of_birth").capitalize, l(claim.date_of_birth)],
        [t("verified_fields.address").capitalize, sanitize(claim.address("<br>").html_safe, tags: %w[br])],
        [t("questions.admin.email_address"), claim.email_address],
      ]
    end

    def admin_student_loan_details(claim)
      [
        [t("student_loans.csv_headers.student_loan_repayment_amount"), number_to_currency(claim.eligibility.student_loan_repayment_amount)],
        [t("student_loans.csv_headers.student_loan_repayment_plan"), claim.student_loan_plan&.humanize],
      ]
    end

    def link_to_school(school)
      url = "https://get-information-schools.service.gov.uk/Establishments/Establishment/Details/#{school.urn}"
      link_to(school.name, url, class: "govuk-link")
    end
  end
end
