module Geckoboard
  class UpdateUncheckedClaimsJob < CronJob
    self.cron_expression = "0 3 * * *"

    def perform
      Claim::GeckoboardDataset.new(Claim.awaiting_checking).save
    end
  end
end
