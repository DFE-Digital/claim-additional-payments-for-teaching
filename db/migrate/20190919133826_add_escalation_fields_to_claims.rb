class AddEscalationFieldsToClaims < ActiveRecord::Migration[5.2]
  def change
    add_column :claims, :escalated_at, :datetime
    add_column :claims, :escalated_by, :string
  end
end
