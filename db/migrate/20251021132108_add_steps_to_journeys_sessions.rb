class AddStepsToJourneysSessions < ActiveRecord::Migration[8.0]
  def change
    add_column :journeys_sessions, :steps, :jsonb, default: []
  end
end
