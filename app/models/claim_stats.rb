class ClaimStats < ApplicationRecord
  self.primary_key = "claim_id"

  def readonly?
    true
  end

  def self.refresh
    Scenic.database.refresh_materialized_view(table_name, concurrently: false, cascade: false)
  end
end
