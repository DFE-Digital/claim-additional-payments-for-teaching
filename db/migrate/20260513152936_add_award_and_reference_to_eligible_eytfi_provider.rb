class AddAwardAndReferenceToEligibleEytfiProvider < ActiveRecord::Migration[8.1]
  def change
    add_column(
      :early_years_teachers_financial_incentive_payments_eligibilities,
      :teacher_reference_number,
      :string
    )
  end
end
