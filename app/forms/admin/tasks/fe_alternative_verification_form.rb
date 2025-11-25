class Admin::Tasks::FeAlternativeVerificationForm < Admin::Tasks::AlternativeVerificationForm
  TASK_NAME = "fe_alternative_verification"

  private

  def practitioner_employed_by_provider?
    eligibility.provider_verification_claimant_employed_by_college
  end

  def provider_confirmed_bank_details?
    eligibility.provider_verification_claimant_bank_details_match
  end

  def answer_not_applicable?
    eligibility.provider_verification_claimant_employed_by_college == false
  end

  def provider_entered_claimant_date_of_birth
    eligibility.provider_verification_claimant_date_of_birth
  end

  def provider_entered_claimant_postcode
    eligibility.provider_verification_claimant_postcode
  end

  def provider_entered_national_insurance_number
    eligibility.provider_verification_claimant_national_insurance_number
  end

  def provider_entered_bank_details_match
    eligibility.provider_verification_claimant_bank_details_match
  end

  def provider_entered_claimant_email
    eligibility.provider_verification_claimant_email
  end

  def awaiting_provider_response?
    eligibility.provider_verification_claimant_employed_by_college.nil?
  end
end
