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

    case claim.eligibility.qualification_name
    when "assessment only"
      I18n.t("early_career_payments.questions.eligible_itt_subject_assessment_only")
    when "overseas recognition qualification"
      I18n.t("early_career_payments.questions.eligible_itt_subject_overseas_recognition")
    else
      I18n.t("early_career_payments.questions.eligible_itt_subject", qualification: claim.eligibility.qualification_name)
    end
  end

  def nqt_h1_text
    policy_year = PolicyConfiguration.for(EarlyCareerPayments).current_academic_year
    last_academic_year_to_display_as_started = AcademicYear.new("2022/2023")
    started_or_completed = policy_year > last_academic_year_to_display_as_started ? :completed : :started
    I18n.t("early_career_payments.questions.nqt_in_academic_year_after_itt.heading", started_or_completed: started_or_completed)
  end

  def nqt_hint_text
    policy_year = PolicyConfiguration.for(EarlyCareerPayments).current_academic_year
    last_academic_year_to_display_as_year = AcademicYear.new("2021/2022")
    year_or_period = policy_year > last_academic_year_to_display_as_year ? :period : :year
    I18n.t("early_career_payments.questions.nqt_in_academic_year_after_itt.hint", year_or_period: year_or_period)
  end

  def graduate_itt?(claim)
    %w[undergraduate_itt postgraduate_itt].include? claim.eligibility.qualification
  end

  def qts?(claim)
    %w[assessment_only overseas_recognition].include? claim.eligibility.qualification
  end

  def itt_subjects(current_claim)
    subjects = IttSubjectSet.from_current_claim(current_claim).subjects
    subjects.map { |sub| t("early_career_payments.answers.eligible_itt_subject.#{sub}") }
      .to_sentence(last_word_connector: " or ")
      .downcase
  end
end
