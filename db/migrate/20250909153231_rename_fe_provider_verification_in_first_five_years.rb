class RenameFeProviderVerificationInFirstFiveYears < ActiveRecord::Migration[8.0]
  def change
    rename_column(
      :further_education_payments_eligibilities,
      :provider_verification_in_first_five_years,
      :provider_verification_teaching_start_year_matches_claim
    )
  end
end
