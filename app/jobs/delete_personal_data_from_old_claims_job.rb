# Runs weekly at 00:30 on a Sunday morning, and instructs the PersonalDataScrubber class
# to remove personal data from eligible claims.
class DeletePersonalDataFromOldClaimsJob < CronJob
  self.cron_expression = "30 0 * * 0"

  def perform
    Rails.logger.info "Deleting personal data from old claims which have been rejected or paid"
    Claim::PersonalDataScrubber.new.scrub_completed_claims
  end
end
