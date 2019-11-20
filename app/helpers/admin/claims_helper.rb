module Admin
  module ClaimsHelper
    include ::ClaimsHelper

    def admin_eligibility_answers(eligibility)
      [].tap do |a|
        a << [t("student_loans.admin.qts_award_year"), I18n.t("questions.qts_award_years.#{eligibility.qts_award_year}")]
        a << [t("student_loans.admin.claim_school"), display_school(eligibility.claim_school)]
        a << [t("admin.current_school"), display_school(eligibility.current_school)]
        a << [t("student_loans.admin.subjects_taught"), subject_list(eligibility.subjects_taught)]
        a << [t("student_loans.admin.had_leadership_position"), (eligibility.had_leadership_position? ? "Yes" : "No")]
        a << [t("student_loans.admin.mostly_performed_leadership_duties"), (eligibility.mostly_performed_leadership_duties? ? "Yes" : "No")] if eligibility.had_leadership_position?
      end
    end

    def admin_personal_details(claim)
      [
        [t("admin.teacher_reference_number"), claim.teacher_reference_number],
        [t("verified_fields.full_name").capitalize, claim.full_name],
        [t("verified_fields.date_of_birth").capitalize, l(claim.date_of_birth, format: :day_month_year)],
        [t("admin.national_insurance_number"), claim.national_insurance_number],
        [t("verified_fields.address").capitalize, sanitize(claim.address("<br>").html_safe, tags: %w[br])],
        [t("admin.email_address"), claim.email_address],
      ]
    end

    def admin_student_loan_details(claim)
      [
        [t("student_loans.admin.student_loan_repayment_amount"), number_to_currency(claim.eligibility.student_loan_repayment_amount)],
        [t("student_loans.admin.student_loan_repayment_plan"), claim.student_loan_plan&.humanize],
      ]
    end

    def admin_submission_details(claim)
      [
        [t("admin.started_at"), l(claim.created_at)],
        [t("admin.submitted_at"), l(claim.submitted_at)],
        [t("admin.check_deadline"), [l(claim.check_deadline_date), check_deadline_warning(claim)].compact.join.html_safe],
      ]
    end

    def admin_check_details(check)
      [].tap do |a|
        a << [t("admin.check.checked_at"), l(check.created_at)]
        a << [t("admin.check.result"), check.result.capitalize]
        a << [t("admin.check.notes"), simple_format(check.notes, class: "govuk-body")] if check.notes.present?
      end
    end

    def link_to_school(school)
      url = "https://get-information-schools.service.gov.uk/Establishments/Establishment/Details/#{school.urn}"
      link_to(school.name, url, class: "govuk-link")
    end

    def display_school(school)
      html = [
        link_to_school(school),
        tag.span("(#{school.dfe_number})", class: "govuk-body-s"),
      ].join(" ").html_safe
      sanitize(html, tags: %w[span a], attributes: %w[href class])
    end

    def check_deadline_warning(claim)
      days_until_check_deadline = days_between(Date.today, claim.check_deadline_date)
      return if days_until_check_deadline.days > Claim::CHECK_DEADLINE_WARNING_POINT

      check_deadline_warning_class = days_until_check_deadline < 0 ? "tag--alert" : "tag--warning"
      content_tag(:strong, pluralize(days_until_check_deadline, "day"), class: "govuk-tag #{check_deadline_warning_class}")
    end

    def matching_attributes(first_claim, second_claim)
      first_attributes = first_claim.attributes.slice(*Claim::MatchingAttributeFinder::ATTRIBUTES_TO_MATCH).to_a
      second_attributes = second_claim.attributes.slice(*Claim::MatchingAttributeFinder::ATTRIBUTES_TO_MATCH).to_a

      matching_attributes = first_attributes & second_attributes
      matching_attributes.to_h.compact.keys.map(&:humanize).sort
    end

    private

    def days_between(first_date, second_date)
      (second_date - first_date).to_i
    end
  end
end
