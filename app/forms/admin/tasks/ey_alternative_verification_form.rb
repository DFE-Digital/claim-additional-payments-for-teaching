class Admin::Tasks::EyAlternativeVerificationForm < Admin::Tasks::AlternativeVerificationForm
  TASK_NAME = "ey_alternative_verification"

  private

  def practitioner_employed_by_provider?
    eligibility.alternative_idv_claimant_employed_by_nursery
  end

  def provider_confirmed_bank_details?
    eligibility.alternative_idv_claimant_bank_details_match
  end

  def answer_not_applicable?
    eligibility.alternative_idv_claimant_employed_by_nursery == false
  end

  def provider_entered_claimant_date_of_birth
    eligibility.alternative_idv_claimant_date_of_birth
  end

  def provider_entered_claimant_postcode
    eligibility.alternative_idv_claimant_postcode
  end

  def provider_entered_national_insurance_number
    eligibility.alternative_idv_claimant_national_insurance_number
  end

  def provider_entered_bank_details_match
    eligibility.alternative_idv_claimant_bank_details_match
  end

  def provider_entered_claimant_email
    eligibility.alternative_idv_claimant_email
  end

  def awaiting_provider_response?
    eligibility.alternative_idv_claimant_employed_by_nursery.nil?
  end
end
