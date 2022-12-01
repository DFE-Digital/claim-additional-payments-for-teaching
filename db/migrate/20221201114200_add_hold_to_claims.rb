class AddHoldToClaims < ActiveRecord::Migration[6.1]
  def change
    add_column :claims, :held, :boolean, default: false
    add_index :claims, :held
  end
end
