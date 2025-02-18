class MigrateLupClaimsToTri < ActiveRecord::Migration[8.0]
  def up
    execute("UPDATE claims SET eligibility_type = 'Policies::TargetedRetentionIncentivePayments::Eligibility' WHERE eligibility_type = 'Policies::LevellingUpPremiumPayments::Eligibility'")
  end
end
