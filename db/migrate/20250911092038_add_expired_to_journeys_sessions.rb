class AddExpiredToJourneysSessions < ActiveRecord::Migration[8.0]
  def change
    add_column :journeys_sessions,
      :expired,
      :boolean,
      null: false,
      default: false
  end
end
