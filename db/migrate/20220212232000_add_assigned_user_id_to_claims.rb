class AddAssignedUserIdToClaims < ActiveRecord::Migration[6.0]
  def change
    add_column :claims, :assigned_to_id, :string
  end
end
