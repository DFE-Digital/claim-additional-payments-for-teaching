class AddPaymentIdToClaims < ActiveRecord::Migration[6.0]
  def change
    add_reference :claims, :payment, type: :uuid, foreign_key: true
  end
end
