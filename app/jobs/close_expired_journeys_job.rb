class CloseExpiredJourneysJob < ApplicationJob
  def perform
    now = Time.current.in_time_zone("London")

    Journeys::Configuration
      .where(open_for_submissions: true)
      .where.not(close_at: nil)
      .find_each do |journey_configuration|
        send_admin_notification_if_due(journey_configuration, now)

        next unless journey_configuration.close_at <= now

        journey_configuration.update!(open_for_submissions: false, close_at: nil)
      end
  end

  private

  def send_admin_notification_if_due(journey_configuration, now)
    return unless journey_configuration.close_at.present?

    due_for_notification_at = [journey_configuration.close_at - 7.days, journey_configuration.close_at - 2.days]

    due_for_notification_at.each do |notification_time|
      next unless notification_time <= now && notification_time > now - 1.minute

      DfeSignIn::User.admin.not_deleted.find_each do |admin_user|
        AdminMailer.service_closing_soon(admin_user.email, journey_name: journey_configuration.journey.journey_name, close_at: journey_configuration.close_at).deliver_now
      end
    end
  end
end
