class BackFillClaimsStartedAt < ActiveRecord::Migration[7.0]
  def up
    execute <<-SQL
      UPDATE claims
      SET started_at = journeys_sessions.created_at
      FROM journeys_sessions
      WHERE claims.journeys_session_id = journeys_sessions.id
      AND claims.started_at IS NULL
    SQL

    execute <<-SQL
      UPDATE claims
      SET started_at = created_at
      WHERE journeys_session_id IS NULL
      AND claims.started_at IS NULL
    SQL
  end

  def down
    Claim.update_all(started_at: nil)
  end
end
