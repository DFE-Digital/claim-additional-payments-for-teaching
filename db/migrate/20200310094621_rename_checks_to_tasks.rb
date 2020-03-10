class RenameChecksToTasks < ActiveRecord::Migration[6.0]
  def change
    rename_table :checks, :tasks
  end
end
