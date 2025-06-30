class AddMoreProviderVerificationAttributesToFeEligibility < ActiveRecord::Migration[8.0]
  def change
    add_column(
      :further_education_payments_eligibilities,
      :provider_verification_contract_covers_full_academic_year,
      :boolean
    )
  end
end
