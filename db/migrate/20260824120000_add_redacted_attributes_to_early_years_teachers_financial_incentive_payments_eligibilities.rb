class AddRedactedAttributesToEarlyYearsTeachersFinancialIncentivePaymentsEligibilities < ActiveRecord::Migration[7.1]
  def change
    add_column :early_years_teachers_financial_incentive_payments_eligibilities,
      :redacted_attributes,
      :jsonb,
      default: {}
  end
end
