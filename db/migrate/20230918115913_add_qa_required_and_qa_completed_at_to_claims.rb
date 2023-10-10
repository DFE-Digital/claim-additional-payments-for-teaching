class AddQaRequiredAndQaCompletedAtToClaims < ActiveRecord::Migration[7.0]
  def change
    add_column :claims, :qa_required, :boolean, default: false
    add_column :claims, :qa_completed_at, :datetime
  end
end
