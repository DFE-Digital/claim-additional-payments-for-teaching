class CreateEarlyYearsPaymentEligibilities < ActiveRecord::Migration[7.0]
  def change
    create_table :early_years_payment_eligibilities, id: :uuid do |t|
      t.timestamps
    end
  end
end
