class RenameChecksToDecisions < ActiveRecord::Migration[6.0]
  def change
    rename_column :checks, :checked_by_id, :created_by_id
    rename_table :checks, :decisions
  end
end
