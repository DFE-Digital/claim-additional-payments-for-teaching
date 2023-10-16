class AddDetailsCheckToClaim < ActiveRecord::Migration[7.0]
  def change
    add_column :claims, :details_check, :boolean
  end
end
