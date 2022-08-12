module EarlyCareerPaymentsHelper
  include ActionView::Helpers::TextHelper

  def one_time_password_validity_duration
    pluralize(OneTimePassword::Base::DRIFT / 60, "minute")
  end

  def graduate_itt?(claim)
    %w[undergraduate_itt postgraduate_itt].include? claim.eligibility.qualification
  end

  def eligible_itt_subject_translation(claim)
    if claim.eligibility.trainee_teacher?
      return I18n.t("early_career_payments.questions.eligible_itt_subject_trainee_teacher")
    end

    qualification_symbol = claim.eligibility.qualification.to_sym
    subjects = subject_symbols(claim)

    if subjects.many?
      I18n.t("early_career_payments.questions.eligible_itt_subject", qualification: qualification_to_substring(qualification_symbol))
    else
      subject_symbol = subjects.first
      I18n.t("early_career_payments.questions.eligible_itt_subject_one_option", qualification: qualification_to_substring(qualification_symbol), subject: subject_symbol)
    end
  end

  private

  def qualification_to_substring(qualification_symbol)
    {
      undergraduate_itt: "undergraduate initial teacher training (ITT)",
      postgraduate_itt: "postgraduate initial teacher training (ITT)",
      assessment_only: "assessment",
      overseas_recognition: "teaching qualification"
    }[qualification_symbol]
  end
end
