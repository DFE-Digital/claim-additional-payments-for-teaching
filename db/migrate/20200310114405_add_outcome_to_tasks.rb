class AddOutcomeToTasks < ActiveRecord::Migration[6.0]
  def change
    add_column :tasks, :passed, :boolean
  end
end
