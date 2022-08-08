module EarlyCareerPaymentsHelper
  include ActionView::Helpers::TextHelper

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
