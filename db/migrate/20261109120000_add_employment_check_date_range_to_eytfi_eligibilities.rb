class AddEmploymentCheckDateRangeToEytfiEligibilities < ActiveRecord::Migration[8.1]
  def change
    change_table :early_years_teachers_financial_incentive_payments_eligibilities do |t|
      t.date :employment_check_date_range_start
      t.date :employment_check_date_range_end
    end
  end
end
