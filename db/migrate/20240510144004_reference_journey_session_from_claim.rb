class ReferenceJourneySessionFromClaim < ActiveRecord::Migration[7.0]
  def change
    add_reference :claims,
      :journeys_session,
      type: :uuid,
      foreign_key: true,
      null: true
  end
end
