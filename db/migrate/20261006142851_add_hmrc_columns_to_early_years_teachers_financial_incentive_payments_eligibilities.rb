class AddHmrcColumnsToEarlyYearsTeachersFinancialIncentivePaymentsEligibilities < ActiveRecord::Migration[8.1]
  def change
    add_column :early_years_teachers_financial_incentive_payments_eligibilities, :hmrc_response_status, :integer
    add_column :early_years_teachers_financial_incentive_payments_eligibilities, :hmrc_response_body, :jsonb
  end
end
