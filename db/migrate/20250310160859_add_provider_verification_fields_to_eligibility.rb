class AddProviderVerificationFieldsToEligibility < ActiveRecord::Migration[8.0]
  def change
    add_column(
      :further_education_payments_eligibilities,
      :claimant_date_of_birth,
      :date
    )

    add_column(
      :further_education_payments_eligibilities,
      :claimant_postcode,
      :string
    )

    add_column(
      :further_education_payments_eligibilities,
      :claimant_national_insurance_number,
      :string
    )

    add_column(
      :further_education_payments_eligibilities,
      :claimant_valid_passport,
      :boolean
    )

    add_column(
      :further_education_payments_eligibilities,
      :claimant_passport_number,
      :string
    )

    add_column(
      :further_education_payments_eligibilities,
      :claimant_identity_verified_at,
      :datetime
    )
  end
end
