class AddResolvedAtToClaimsMatches < ActiveRecord::Migration[8.1]
  def change
    add_column :claims_matches, :resolved_at, :timestamp
  end
end
