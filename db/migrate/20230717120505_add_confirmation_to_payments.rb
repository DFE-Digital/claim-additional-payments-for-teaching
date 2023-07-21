class AddConfirmationToPayments < ActiveRecord::Migration[7.0]
  def up
    add_reference :payments, :confirmation, type: :uuid, foreign_key: {to_table: :payment_confirmations}
  end

  def down
    remove_reference :payments, :confirmation, type: :uuid, foreign_key: {to_table: :payment_confirmations}
  end
end
