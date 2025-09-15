# Runs nightly at midnight and deletes any unsubmitted claims that are more than
# 24 hours old, purging our database of data we don't want or need to hang on
# to.
class PurgeUnsubmittedClaimsJob < ApplicationJob
  def perform
    Journeys::JOURNEYS.each do |journey|
      Rails.logger.info "Purging #{journey::Session.purgeable.count} old and unsubmitted #{journey::Session} journeys from the database"
      journey::Session.where(journey: journey::ROUTING_NAME).purgeable.destroy_all
    end
  end
end
