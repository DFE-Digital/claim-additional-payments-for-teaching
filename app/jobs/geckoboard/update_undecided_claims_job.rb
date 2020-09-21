module Geckoboard
  class UpdateUndecidedClaimsJob < CronJob
    self.cron_expression = "0 3 * * *"

    def perform
      claims_to_update = []
      Policies.all.each do |policy|
        policy_configuration = PolicyConfiguration.for(policy)
        claims_to_update += Claim.by_policy(policy).by_academic_year(policy_configuration.current_academic_year).awaiting_decision
      end
      Claim::GeckoboardDataset.new(claims: claims_to_update).save
    end
  end
end
