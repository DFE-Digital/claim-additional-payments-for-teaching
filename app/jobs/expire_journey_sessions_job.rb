# expire journey sessions so they are no longer available to browsers
# we still keep them persisted incase user wishes to resume
class ExpireJourneySessionsJob < ApplicationJob
  def perform
    Journeys::JOURNEYS.each do |journey|
      Rails.logger.info "Expiring #{journey::Session.purgeable.count} #{journey::Session} journeys from the database"
      journey::Session
        .where(journey: journey.routing_name)
        .expirable
        .update_all(expired: true)
    end
  end
end
