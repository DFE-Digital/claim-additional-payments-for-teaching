class AddEligibleEytfiProviderToEytfiEligibilities < ActiveRecord::Migration[8.1]
  def change
    add_reference(
      :early_years_teachers_financial_incentive_payments_eligibilities,
      :eligible_eytfi_provider,
      type: :uuid,
      foreign_key: true,
      null: false
    )
  end
end
