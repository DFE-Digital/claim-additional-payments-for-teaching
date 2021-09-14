module EarlyCareerPaymentsHelper
  def ineligible_heading(claim)
    if claim.eligibility.ineligibility_reason == :poor_performance
      content_tag(:h1, I18n.t("early_career_payments.ineligible.poor_performance_heading"), class: "govuk-heading-xl")
    elsif claim.eligibility.ineligibility_reason == :ineligible_current_school
      content_tag(:h1, I18n.t("early_career_payments.ineligible.school_heading"), class: "govuk-heading-xl")
    else
      content_tag(:h1, I18n.t("early_career_payments.ineligible.heading"), class: "govuk-heading-xl")
    end
  end

  def one_time_password_validity_duration
    pluralize(OneTimePassword::Base::DRIFT / 60, "minute")
  end

  def eligible_itt_subject_translation(claim)
    if claim.eligibility.trainee_teacher_in_2021?
      I18n.t("early_career_payments.questions.eligible_itt_subject_trainee_teacher_in_2021")
    else
      I18n.t("early_career_payments.questions.eligible_itt_subject", qualification: claim.eligibility.qualification_name)
    end
  end
end
