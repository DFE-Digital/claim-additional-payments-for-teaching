class IndexJourneySessionUpdatedAt < ActiveRecord::Migration[8.1]
  def change
    add_index :journeys_sessions, :updated_at
  end
end
