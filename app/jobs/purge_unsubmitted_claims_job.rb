# Runs nightly at midnight and deletes any unsubmitted claims that are more than
# 24 hours old, purging our database of data we don't want or need to hang on
# to.
class PurgeUnsubmittedClaimsJob < ApplicationJob
  def perform
    Rails.logger.info "Purging #{old_unsubmitted_journeys.count} old and unsubmitted journeys from the database"
    old_unsubmitted_journeys.destroy_all
  end

  private

  def old_unsubmitted_journeys
    Journeys::Session.purgeable
  end
end
