class AddCloseDateAndTimeToJourneyConfigurations < ActiveRecord::Migration[7.1]
  def change
    add_column :journey_configurations, :close_at, :datetime, default: -> { "CURRENT_TIMESTAMP + interval '1 year'" }, null: false
  end
end
