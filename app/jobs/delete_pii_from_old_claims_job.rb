# Runs weekly at 00:30 on a Sunday morning, and instructs the PiiScrubber class
# to remove PII from eligible claims.
class DeletePiiFromOldClaimsJob < CronJob
  self.cron_expression = "30 0 * * 0"

  def perform
    Rails.logger.info "Deleting PII from old claims which have been rejected or paid"
    Claim::PiiScrubber.new.scrub_completed_claims
  end
end
