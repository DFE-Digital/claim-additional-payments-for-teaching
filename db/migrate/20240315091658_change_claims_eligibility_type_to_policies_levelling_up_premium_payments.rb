class ChangeClaimsEligibilityTypeToPoliciesLevellingUpPremiumPayments < ActiveRecord::Migration[7.0]
  def change
    reversible do |dir|
      dir.up do
        Claim.where(eligibility_type: "LevellingUpPremiumPayments::Eligibility").update_all(eligibility_type: "Policies::LevellingUpPremiumPayments::Eligibility")
      end

      dir.down do
        Claim.where(eligibility_type: "Policies::LevellingUpPremiumPayments::Eligibility").update_all(eligibility_type: "LevellingUpPremiumPayments::Eligibility")
      end
    end
  end
end
