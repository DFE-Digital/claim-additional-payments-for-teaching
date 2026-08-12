class CloseExpiredJourneysJob < ApplicationJob
  def perform
    now = Time.current.in_time_zone("London").round(0)

    Journeys::Configuration
      .where(open_for_submissions: true)
      .where.not(close_at: nil)
      .find_each do |journey_configuration|
        send_admin_notification_if_due(journey_configuration, now)

        close_at = journey_configuration.close_at.in_time_zone("London")
        next unless close_at.round(0) <= now + 1.second

        journey_configuration.update!(open_for_submissions: false, close_at: nil)
      end
  end

  private

  def send_admin_notification_if_due(journey_configuration, now)
    close_at = journey_configuration.close_at&.in_time_zone("London")
    return unless close_at.present?

    due_for_notification_at = [close_at - 7.days, close_at - 2.days]

    due_for_notification_at.each do |notification_time|
      notification_time_for_comparison = notification_time.round(0)
      next unless notification_time_for_comparison.between?(now - 1.minute, now + 1.second)

      DfeSignIn::User.admin.not_deleted.find_each do |admin_user|
        AdminMailer.service_closing_soon(admin_user.email, journey_name: journey_configuration.journey.journey_name, close_at: journey_configuration.close_at).deliver_now
      end
    end
  end
end
