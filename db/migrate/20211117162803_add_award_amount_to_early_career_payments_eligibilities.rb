class AddAwardAmountToEarlyCareerPaymentsEligibilities < ActiveRecord::Migration[6.0]
  def change
    add_column :early_career_payments_eligibilities, :award_amount, :decimal, precision: 7, scale: 2
  end
end
