class AddAwardAmountToFurtherEducationPaymentsEligibilities < ActiveRecord::Migration[7.0]
  def change
    add_column :further_education_payments_eligibilities, :award_amount, :decimal, precision: 7, scale: 2
  end
end
