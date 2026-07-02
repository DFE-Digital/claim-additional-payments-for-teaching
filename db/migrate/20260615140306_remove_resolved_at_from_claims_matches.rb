class RemoveResolvedAtFromClaimsMatches < ActiveRecord::Migration[8.1]
  def change
    remove_column(
      :claims_matches,
      :resolved_at,
      :datetime
    )
  end
end
