class RemoveCheckedByFromDecisions < ActiveRecord::Migration[6.0]
  def change
    remove_column :decisions, :checked_by
  end
end
