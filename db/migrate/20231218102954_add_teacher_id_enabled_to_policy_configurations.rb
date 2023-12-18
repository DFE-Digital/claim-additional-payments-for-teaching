class AddTeacherIdEnabledToPolicyConfigurations < ActiveRecord::Migration[7.0]
  def change
    add_column :policy_configurations, :teacher_id_enabled, :boolean, default: true
  end
end
