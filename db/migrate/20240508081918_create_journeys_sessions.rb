class CreateJourneysSessions < ActiveRecord::Migration[7.0]
  def change
    create_table :journeys_sessions, id: :uuid do |t|
      t.jsonb :answers, default: {}
      t.string :journey, null: false

      t.timestamps
    end
  end
end
