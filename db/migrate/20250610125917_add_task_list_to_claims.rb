class AddTaskListToClaims < ActiveRecord::Migration[8.0]
  def change
    add_column :claims, :task_list, :text, array: true, default: []
  end
end
