class AddDecisionDeadlineToClaim < ActiveRecord::Migration[8.1]
  def change
    add_column :claims, :decision_deadline, :date, null: true
    add_index :claims, :decision_deadline
  end
end
