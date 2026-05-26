# Runs nightly at midnight and deletes any unsubmitted claims that are more than
# 24 hours old, purging our database of data we don't want or need to hang on
# to.
class PurgeUnsubmittedClaimsJob < ApplicationJob
  def perform
    Journeys::JOURNEYS.each do |journey|
      purgeable = journey::Session.where(journey: journey.routing_name).purgeable
      Rails.logger.info "Purging #{purgeable.count} old and unsubmitted #{journey::Session} journeys from the database"

      purgeable.in_batches(&:destroy_all)
    end
  end
end
