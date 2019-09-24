class RemoveApprovalFieldsFromClaim < ActiveRecord::Migration[5.2]
  def change
    remove_column :claims, :approved_at, :datetime
    remove_column :claims, :approved_by, :string
  end
end
