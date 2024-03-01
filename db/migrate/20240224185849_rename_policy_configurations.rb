class RenamePolicyConfigurations < ActiveRecord::Migration[7.0]
  def change
    rename_table :policy_configurations, :journey_configurations
  end
end
