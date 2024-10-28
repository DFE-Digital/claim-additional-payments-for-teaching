class AddColumnsToEarlyYearsPaymentEligibilities < ActiveRecord::Migration[7.0]
  def change
    add_column :early_years_payment_eligibilities, :provider_email_address, :string
    add_column :early_years_payment_eligibilities, :returner_worked_with_children, :boolean
    add_column :early_years_payment_eligibilities, :returner_contract_type, :string
    add_column :early_years_payment_eligibilities, :award_amount, :decimal, precision: 7, scale: 2
  end
end
