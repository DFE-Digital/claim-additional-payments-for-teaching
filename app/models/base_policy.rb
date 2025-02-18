# frozen_string_literal: true

module BasePolicy
  def to_s
    super.demodulize
  end

  def policy_type
    locale_key.dasherize
  end

  def short_name
    I18n.t("#{locale_key}.policy_short_name")
  end

  def support_email_address
    I18n.t("#{locale_key}.support_email_address")
  end

  def locale_key
    to_s.underscore
  end

  def payroll_file_name
    to_s
  end

  def eligibility_matching_attributes
    return [] unless const_defined?(:ELIGIBILITY_MATCHING_ATTRIBUTES)

    self::ELIGIBILITY_MATCHING_ATTRIBUTES
  end

  def searchable_eligibility_attributes
    return [] unless const_defined?(:SEARCHABLE_ELIGIBILITY_ATTRIBUTES)

    self::SEARCHABLE_ELIGIBILITY_ATTRIBUTES
  end

  def international_relocation_payments?
    to_s == "InternationalRelocationPayments"
  end

  def further_education_payments?
    to_s == "FurtherEducationPayments"
  end

  def auto_check_student_loan_plan_task?
    false
  end

  def approvable?(claim)
    true
  end

  def decision_deadline_date(claim)
    (claim.submitted_at + Claim::DECISION_DEADLINE).to_date
  end

  def award_amount_column
    "award_amount"
  end

  def mailer
    ClaimMailer
  end

  def task_available?(task)
    true
  end

  def require_in_progress_update_emails?
    true
  end

  # Overwrite this in the policies if they set a maximum topup amount
  def max_topup_amount(claim)
    10_000.00
  end

  def current_academic_year
    Journeys.for_policy(self).configuration.current_academic_year
  end
end
