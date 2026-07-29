class AddCloseDateAndTimeToJourneyConfigurations < ActiveRecord::Migration[7.1]
  def change
    add_column :journey_configurations, :close_date, :date
    add_column :journey_configurations, :close_time, :time
  end
end
