class CloseExpiredJourneysJob < ApplicationJob
  def perform
    now = Time.current.in_time_zone("London")

    Journeys::Configuration
      .where(open_for_submissions: true)
      .where.not(close_at: nil)
      .where("close_at <= ?", now)
      .find_each do |journey_configuration|
        journey_configuration.update!(open_for_submissions: false, close_at: nil)
      end
  end
end
