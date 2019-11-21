class AddGrossPayToPayments < ActiveRecord::Migration[6.0]
  def change
    add_column :payments, :gross_pay, :decimal, precision: 7, scale: 2
  end
end
