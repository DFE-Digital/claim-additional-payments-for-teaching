class AddHmrcEmploymentCheckAttemptsToEytfiEligibilities < ActiveRecord::Migration[8.1]
  def change
    add_column(
      :early_years_teachers_financial_incentive_payments_eligibilities,
      :hmrc_employment_check_attempts,
      :integer,
      default: 0,
      null: false
    )
  end
end
