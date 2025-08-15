class AddAltIdvFieldsToEyEligibilities < ActiveRecord::Migration[8.0]
  def change
    add_column(
      :early_years_payment_eligibilities,
      :alternative_idv_claimant_employed_by_nursery,
      :boolean
    )

    add_column(
      :early_years_payment_eligibilities,
      :alternative_idv_claimant_date_of_birth,
      :date
    )

    add_column(
      :early_years_payment_eligibilities,
      :alternative_idv_claimant_postcode,
      :string
    )

    add_column(
      :early_years_payment_eligibilities,
      :alternative_idv_claimant_national_insurance_number,
      :string
    )

    add_column(
      :early_years_payment_eligibilities,
      :alternative_idv_claimant_bank_details_match,
      :boolean
    )

    add_column(
      :early_years_payment_eligibilities,
      :alternative_idv_claimant_email,
      :string
    )

    add_column(
      :early_years_payment_eligibilities,
      :alternative_idv_claimant_employment_check_declaration,
      :boolean
    )

    add_column(
      :early_years_payment_eligibilities,
      :alternative_idv_completed_at,
      :datetime
    )
  end
end
