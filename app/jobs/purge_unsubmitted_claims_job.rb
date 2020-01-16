# Runs nightly at midnight and deletes any unsubmitted claims that are more than
# 24 hours old, purging our database of data we don't want or need to hang on
# to.
class PurgeUnsubmittedClaimsJob < CronJob
  self.cron_expression = "0 0 * * *"

  def perform
    Rails.logger.info "Purging #{old_unsubmitted_claims.count} old and unsubmitted claims from the database"
    old_unsubmitted_claims.destroy_all
  end

  private

  def old_unsubmitted_claims
    Claim.unsubmitted.where("updated_at < ?", 24.hours.ago)
  end
end
