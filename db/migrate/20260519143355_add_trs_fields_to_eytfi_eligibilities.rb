class AddTrsFieldsToEytfiEligibilities < ActiveRecord::Migration[8.1]
  def change
    add_column(
      :early_years_teachers_financial_incentive_payments_eligibilities,
      :trs_data,
      :jsonb
    )

    add_column(
      :early_years_teachers_financial_incentive_payments_eligibilities,
      :trs_data_fetched_at,
      :datetime
    )
  end
end
