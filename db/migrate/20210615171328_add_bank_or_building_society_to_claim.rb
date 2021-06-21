class AddBankOrBuildingSocietyToClaim < ActiveRecord::Migration[6.0]
  def change
    add_column :claims, :bank_or_building_society, :integer
  end
end
