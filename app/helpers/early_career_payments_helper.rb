module EarlyCareerPaymentsHelper
  def ineligible_heading(claim)
    if claim.eligibility.ineligibility_reason == :poor_performance
      content_tag(:h1, I18n.t("early_career_payments.ineligible.poor_performance_heading"), class: "govuk-heading-xl")
    elsif claim.eligibility.ineligibility_reason == :ineligible_current_school
      content_tag(:h1, I18n.t("early_career_payments.ineligible.school_heading"), class: "govuk-heading-xl")
    elsif claim.eligibility.ineligibility_reason == :ineligible_nqt_in_academic_year_after_itt
      content_tag(:h1, I18n.t("early_career_payments.ineligible.reason.nqt_after_itt"), class: "govuk-heading-l")
    else
      content_tag(:h1, I18n.t("early_career_payments.ineligible.heading"), class: "govuk-heading-xl")
    end
  end

  def one_time_password_validity_duration
    pluralize(OneTimePassword::OTP_PASSWORD_INTERVAL / 60, "minute")
  end
end
