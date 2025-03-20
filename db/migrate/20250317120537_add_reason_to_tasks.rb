class AddReasonToTasks < ActiveRecord::Migration[8.0]
  def change
    add_column :tasks, :reason, :text, null: true
  end
end
