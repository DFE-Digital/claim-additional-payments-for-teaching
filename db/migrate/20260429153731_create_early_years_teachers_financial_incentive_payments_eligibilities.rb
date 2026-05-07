class CreateEarlyYearsTeachersFinancialIncentivePaymentsEligibilities < ActiveRecord::Migration[8.1]
  def change
    create_table :early_years_teachers_financial_incentive_payments_eligibilities, id: :uuid do |t|
      t.timestamps

      t.decimal :award_amount, precision: 7, scale: 2
    end
  end
end
