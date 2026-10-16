class AddTrsNationalInsuranceNumberToEarlyYearsTeachersFinancialIncentivePaymentsEligibilities < ActiveRecord::Migration[8.1]
  def change
    add_column(
      :early_years_teachers_financial_incentive_payments_eligibilities,
      :trs_national_insurance_number,
      :string
    )
  end
end
