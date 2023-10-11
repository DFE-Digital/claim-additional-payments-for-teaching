class DropAnalyticsViews < ActiveRecord::Migration[7.0]
  def up
    execute("DROP MATERIALIZED VIEW IF EXISTS claim_stats")
    execute("DROP VIEW IF EXISTS claim_decisions")
  end

  def down
    # Do nothing; revert commit to retrieve necessary migrations and libraries.
  end
end
