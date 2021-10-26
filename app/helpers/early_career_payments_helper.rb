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

  def guidance_eligibility_page_link(claim)
    eligibility_page_url = if claim.eligibility.send(:no_entire_term_contract?)
      EarlyCareerPayments.eligibility_page_url + "#supply-private-school-and-sixth-form-college-teachers"
    elsif claim.eligibility.send(:not_teaching_now_in_eligible_itt_subject?)
      EarlyCareerPayments.eligibility_page_url + "#eligibility-criteria"
    else
      EarlyCareerPayments.eligibility_page_url
    end
    link_to("eligibility page", eligibility_page_url, class: "govuk-link")
  end

  def one_time_password_validity_duration
    pluralize(OneTimePassword::Base::DRIFT / 60, "minute")
  end

  def eligible_itt_subject_translation(claim)
    if claim.eligibility.trainee_teacher_in_2021?
      I18n.t("early_career_payments.questions.eligible_itt_subject_trainee_teacher_in_2021")
    elsif claim.eligibility.qualification_name == "overseas recognition qualification"
      I18n.t("early_career_payments.questions.eligible_itt_subject_overseas_recognition")
    else
      I18n.t("early_career_payments.questions.eligible_itt_subject", qualification: claim.eligibility.qualification_name)
    end
  end

  def nqt_h1_text(claim)
    policy_year = PolicyConfiguration.for(EarlyCareerPayments).current_academic_year.to_s
    started_or_completed = policy_year == "2022/2023" ? :started : :completed
    case policy_year
    when "2021/2022"
      I18n.t("early_career_payments.questions.nqt_in_academic_year_after_itt.heading.2021")
    else
      I18n.t("early_career_payments.questions.nqt_in_academic_year_after_itt.heading.default", started_or_completed: started_or_completed)
    end
  end

  def nqt_hint_text(claim)
    policy_year = PolicyConfiguration.for(EarlyCareerPayments).current_academic_year.to_s
    year_or_period = policy_year == "2021/2022" ? :year : :period
    I18n.t("early_career_payments.questions.nqt_in_academic_year_after_itt.hint", year_or_period: year_or_period)
  end
end
