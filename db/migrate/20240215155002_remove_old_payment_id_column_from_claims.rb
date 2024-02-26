class RemoveOldPaymentIdColumnFromClaims < ActiveRecord::Migration[7.0]
  def change
    remove_column :claims, :remove_column_payment_id
  end
end
