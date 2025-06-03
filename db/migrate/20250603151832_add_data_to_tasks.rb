class AddDataToTasks < ActiveRecord::Migration[8.0]
  def change
    add_column :tasks, :data, :jsonb
  end
end
