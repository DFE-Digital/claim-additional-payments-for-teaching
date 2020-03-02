module Admin
  module ClaimsHelper
    include StudentLoans::PresenterMethods

    def confirming_identity_playbook_url
      "https://docs.google.com/document/d/1wZh68_RV_FTJLxXIDPr3XFtJHW3vRgiXGaBDUo1Q1ZU"
    end

    def admin_eligibility_answers(claim)
      claim.policy::EligibilityAdminAnswersPresenter.new(claim.eligibility).answers
    end

    def pii_removed_text
      content_tag(:span, "Removed", class: "capt-text-quiet")
    end

    def admin_personal_details(claim)
      [
        [t("admin.teacher_reference_number"), claim.teacher_reference_number],
        [t("govuk_verify_fields.full_name").capitalize, claim.pii_removed? ? pii_removed_text : claim.full_name],
        [t("govuk_verify_fields.date_of_birth").capitalize, claim.pii_removed? ? pii_removed_text : l(claim.date_of_birth, format: :day_month_year)],
        [t("admin.national_insurance_number"), claim.pii_removed? ? pii_removed_text : claim.national_insurance_number],
        [t("govuk_verify_fields.address").capitalize, claim.pii_removed? ? pii_removed_text : sanitize(claim.address("<br>").html_safe, tags: %w[br])],
        [t("admin.email_address"), claim.email_address]
      ]
    end

    def admin_student_loan_details(claim)
      [].tap do |a|
        a << [t("student_loans.admin.student_loan_repayment_amount"), number_to_currency(claim.eligibility.student_loan_repayment_amount)] if claim.eligibility.respond_to?(:student_loan_repayment_amount)
        a << [t("student_loans.admin.student_loan_repayment_plan"), claim.student_loan_plan&.humanize]
      end
    end

    def admin_submission_details(claim)
      [
        [t("admin.started_at"), l(claim.created_at)],
        [t("admin.submitted_at"), l(claim.submitted_at)],
        [t("admin.decision_deadline"), [l(claim.decision_deadline_date), decision_deadline_warning(claim)].compact.join.html_safe]
      ]
    end

    def admin_decision_details(decision)
      [].tap do |a|
        a << [t("admin.decision.created_at"), l(decision.created_at)]
        a << [t("admin.decision.result"), decision.result.capitalize]
        a << [t("admin.decision.notes"), simple_format(decision.notes, class: "govuk-body")] if decision.notes.present?
        a << [t("admin.decision.created_by"), user_details(decision.created_by)]
      end
    end

    def decision_deadline_warning(claim)
      days_until_decision_deadline = days_between(Date.today, claim.decision_deadline_date)
      return if days_until_decision_deadline.days > Claim::DECISION_DEADLINE_WARNING_POINT

      decision_deadline_warning_class = days_until_decision_deadline < 0 ? "tag--alert" : "tag--warning"
      content_tag(:strong, pluralize(days_until_decision_deadline, "day"), class: "govuk-tag #{decision_deadline_warning_class}")
    end

    def id_verification_status(claim)
      claim.identity_confirmed? ? "GOV.UK Verify" : content_tag(:strong, "Unverified", class: "govuk-tag tag--warning")
    end

    def matching_attributes(first_claim, second_claim)
      first_attributes = matching_attributes_for(first_claim)
      second_attributes = matching_attributes_for(second_claim)

      matching_attributes = first_attributes & second_attributes
      matching_attributes.to_h.compact.keys.map(&:humanize).sort
    end

    private

    def matching_attributes_for(claim)
      claim.attributes
        .slice(*Claim::MatchingAttributeFinder::ATTRIBUTE_GROUPS_TO_MATCH.flatten)
        .reject { |_, v| v.blank? }
        .to_a
    end

    def days_between(first_date, second_date)
      (second_date - first_date).to_i
    end
  end
end
