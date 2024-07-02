class AddAwardAmountToInternationalRelocationPaymentsEligibilities < ActiveRecord::Migration[7.0]
  def change
    add_column :international_relocation_payments_eligibilities, :award_amount, :decimal, precision: 7, scale: 2
  end
end
