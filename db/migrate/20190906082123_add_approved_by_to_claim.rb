class AddApprovedByToClaim < ActiveRecord::Migration[5.2]
  def change
    add_column :claims, :approved_by, :string
  end
end
