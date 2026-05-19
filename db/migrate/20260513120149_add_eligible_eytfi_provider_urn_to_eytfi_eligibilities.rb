class AddEligibleEytfiProviderUrnToEytfiEligibilities < ActiveRecord::Migration[8.1]
  def change
    add_column(
      :early_years_teachers_financial_incentive_payments_eligibilities,
      :eligible_eytfi_provider_urn,
      :string
    )
  end
end
