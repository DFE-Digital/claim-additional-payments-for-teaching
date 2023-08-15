class AddConfirmationAndPaymentDateToPayments < ActiveRecord::Migration[7.0]
  def change
    add_reference :payments, :confirmation, type: :uuid, foreign_key: {to_table: :payment_confirmations}
    add_column :payments, :scheduled_payment_date, :date
  end
end
