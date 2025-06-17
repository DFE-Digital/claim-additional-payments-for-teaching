class RemoveExtraIndexesOnJourneyConfigurations < ActiveRecord::Migration[8.0]
  def up
    remove_index :journey_configurations, name: :index_journey_configurations_on_created_at
  end

  def down
    add_index :journey_configurations, :created_at, name: :index_journey_configurations_on_created_at
  end
end
