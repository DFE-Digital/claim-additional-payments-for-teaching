class AddProviderVerificationEmploymentCheckFieldsToFeEligibilities < ActiveRecord::Migration[8.0]
  def change
    add_column(
      :further_education_payments_eligibilities,
      :provider_verification_claimant_employed_by_college,
      :boolean
    )

    add_column(
      :further_education_payments_eligibilities,
      :provider_verification_claimant_date_of_birth,
      :date
    )

    add_column(
      :further_education_payments_eligibilities,
      :provider_verification_claimant_postcode,
      :string
    )

    add_column(
      :further_education_payments_eligibilities,
      :provider_verification_claimant_national_insurance_number,
      :string
    )

    add_column(
      :further_education_payments_eligibilities,
      :provider_verification_claimant_bank_details_match,
      :boolean
    )

    add_column(
      :further_education_payments_eligibilities,
      :provider_verification_claimant_email,
      :string
    )

    add_column(
      :further_education_payments_eligibilities,
      :provider_verification_claimant_employment_check_declaration,
      :boolean
    )
  end
end
