module EarlyCareerPaymentsHelper
  def ineligible_heading(claim)
    if claim.eligibility.ineligibility_reason == :subject_to_formal_performance_action
      content_tag(:h1, I18n.t("early_career_payments.ineligible.poor_performance_heading"), class: "govuk-heading-xl")
    elsif claim.eligibility.ineligibility_reason == :ineligible_current_school
      content_tag(:h1, I18n.t("early_career_payments.ineligible.school_heading"), class: "govuk-heading-xl")
    else
      content_tag(:h1, I18n.t("early_career_payments.ineligible.heading"), class: "govuk-heading-xl")
    end
  end
end
