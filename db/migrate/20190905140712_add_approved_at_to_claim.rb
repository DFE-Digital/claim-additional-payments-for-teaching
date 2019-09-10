class AddApprovedAtToClaim < ActiveRecord::Migration[5.2]
  def change
    add_column :claims, :approved_at, :datetime
  end
end
