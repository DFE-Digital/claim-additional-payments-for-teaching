class AddUuidIdToJourneyConfigs < ActiveRecord::Migration[8.1]
  def change
    add_column :journey_configurations, :id, :uuid, default: "gen_random_uuid()", null: false

    add_index :journey_configurations, :id, unique: true
  end
end
