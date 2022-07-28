module EarlyCareerPaymentsHelper
  include ActionView::Helpers::TextHelper

  def ineligible_heading(claim)
    if claim.eligibility.ineligibility_reason == :poor_performance
      content_tag(:h1, I18n.t("early_career_payments.ineligible.poor_performance_heading"), class: "govuk-heading-xl")
    elsif claim.eligibility.ineligibility_reason == :ineligible_current_school
      content_tag(:h1, I18n.t("early_career_payments.ineligible.school_heading"), class: "govuk-heading-xl")
    else
      content_tag(:h1, I18n.t("early_career_payments.ineligible.heading"), class: "govuk-heading-xl")
    end
  end

  # TODO: This calls private `Eligibility` methods using `#send` which makes refactoring difficult.
  # There ought to be a separate class which looks at an `Eligibility` and tells you
  # why it's ineligible. *This is too tightly coupled*. LUP and ECP eligibility are so similar
  # there ought to be a new class which deals with the common rules for both.
  def guidance_eligibility_page_link(claim)
    eligibility_page_url = if claim.eligibility.send(:no_entire_term_contract?)
      EarlyCareerPayments.eligibility_page_url + "#supply-private-school-and-sixth-form-college-teachers"
    elsif claim.eligibility.send(:itt_subject_none_of_the_above?) ||
        claim.eligibility.send(:ineligible_cohort?) ||
        claim.eligibility.send(:not_employed_directly?)
      EarlyCareerPayments.eligibility_page_url + "#eligibility-criteria"
    elsif claim.eligibility.send(:not_teaching_now_in_eligible_itt_subject?)
      EarlyCareerPayments.eligibility_page_url + "#employment"
    elsif claim.eligibility.send(:poor_performance?)
      EarlyCareerPayments.eligibility_page_url + "#performance"
    else
      EarlyCareerPayments.eligibility_page_url
    end

    link_to("eligibility page", eligibility_page_url, class: "govuk-link")
  end

  def one_time_password_validity_duration
    pluralize(OneTimePassword::Base::DRIFT / 60, "minute")
  end

  def eligible_itt_subject_translation(claim)
    if claim.eligibility.trainee_teacher?
      return I18n.t("early_career_payments.questions.eligible_itt_subject_trainee_teacher")
    end

    case qualification_name(claim.eligibility.qualification)
    when "assessment only"
      I18n.t("early_career_payments.questions.eligible_itt_subject_assessment_only")
    when "overseas recognition qualification"
      I18n.t("early_career_payments.questions.eligible_itt_subject_overseas_recognition")
    else
      I18n.t("early_career_payments.questions.eligible_itt_subject", qualification: qualification_name(claim.eligibility.qualification))
    end
  end

  def graduate_itt?(claim)
    %w[undergraduate_itt postgraduate_itt].include? claim.eligibility.qualification
  end

  def qts?(claim)
    %w[assessment_only overseas_recognition].include? claim.eligibility.qualification
  end

  def qualification_name(qualification)
    return qualification.gsub("_itt", " initial teaching training") if qualification.split("_").last == "itt"

    qualification_attained = qualification.humanize.downcase

    qualification_attained == "assessment only" ? qualification_attained : qualification_attained + " qualification"
  end
end
