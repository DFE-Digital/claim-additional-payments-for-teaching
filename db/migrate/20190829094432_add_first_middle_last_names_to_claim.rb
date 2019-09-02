class AddFirstMiddleLastNamesToClaim < ActiveRecord::Migration[5.2]
  def change
    add_column :claims, :first_name, :string, limit: 100
    add_column :claims, :middle_name, :string, limit: 100
    add_column :claims, :surname, :string, limit: 100
  end
end
