class AddRejectionsToClaims < ActiveRecord::Migration[5.2]
  def change
    add_column :claims, :rejected_at, :datetime
    add_column :claims, :rejected_by, :string
  end
end
