class AddBankingNameAndBuildingSocietyRollNumberToClaim < ActiveRecord::Migration[5.2]
  def change
    add_column :claims, :banking_name, :string
    add_column :claims, :building_society_roll_number, :string
  end
end
