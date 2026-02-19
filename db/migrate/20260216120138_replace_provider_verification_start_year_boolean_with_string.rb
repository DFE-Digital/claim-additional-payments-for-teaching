class ReplaceProviderVerificationStartYearBooleanWithString < ActiveRecord::Migration[8.0]
  def change
    add_column(
      :further_education_payments_eligibilities,
      :provider_verification_teaching_start_year,
      :string
    )

    remove_column(
      :further_education_payments_eligibilities,
      :provider_verification_teaching_start_year_matches_claim,
      :boolean
    )
  end
end
