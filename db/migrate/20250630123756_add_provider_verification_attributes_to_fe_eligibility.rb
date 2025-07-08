class AddProviderVerificationAttributesToFeEligibility < ActiveRecord::Migration[8.0]
  def change
    add_column(
      :further_education_payments_eligibilities,
      :provider_verification_teaching_responsibilities,
      :boolean
    )

    add_column(
      :further_education_payments_eligibilities,
      :provider_verification_in_first_five_years,
      :boolean
    )

    add_column(
      :further_education_payments_eligibilities,
      :provider_verification_teaching_qualification,
      :string
    )

    add_column(
      :further_education_payments_eligibilities,
      :provider_verification_contract_type,
      :string
    )
  end
end
