module Geckoboard
  class UpdateUndecidedClaimsJob < CronJob
    self.cron_expression = "0 3 * * *"

    def perform
      Claim::GeckoboardDataset.new(claims: Claim.awaiting_decision).save
    end
  end
end
