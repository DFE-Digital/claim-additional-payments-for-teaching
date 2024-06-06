module AdditionalPaymentsHelper
  include ActionView::Helpers::TextHelper

  def one_time_password_validity_duration
    pluralize(OneTimePassword::Base::DRIFT / 60, "minute")
  end

  def eligible_itt_subject_translation(claim, answers)
    if claim.eligibility.trainee_teacher?
      return I18n.t("additional_payments.forms.eligible_itt_subject.questions.which_subject_trainee_teacher")
    end

    qualification_symbol = answers.qualification.to_sym
    subjects = subject_symbols(claim)

    if subjects.many?
      I18n.t("additional_payments.forms.eligible_itt_subject.questions.which_subject", qualification: qualification_to_substring(qualification_symbol))
    else
      subject_symbol = subjects.first
      I18n.t("additional_payments.forms.eligible_itt_subject.questions.single_subject", qualification: qualification_to_substring(qualification_symbol), subject: subject_symbol)
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
