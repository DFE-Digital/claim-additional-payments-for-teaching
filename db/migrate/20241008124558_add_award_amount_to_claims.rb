class AddAwardAmountToClaims < ActiveRecord::Migration[7.0]
  def change
    add_column :claims, :award_amount, :decimal, precision: 7, scale: 2
  end
end
