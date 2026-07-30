class CloseExpiredJourneysJob < ApplicationJob
  def perform
    now = Time.current.in_time_zone("London").to_i

    Journeys::Configuration
      .where(open_for_submissions: true)
      .where.not(close_at: nil)
      .find_each do |journey_configuration|
        send_admin_notification_if_due(journey_configuration, now)

        close_at = journey_configuration.close_at&.in_time_zone("London")&.to_i
        next unless close_at.present? && close_at <= now

        journey_configuration.update!(open_for_submissions: false, close_at: nil)
      end
  end

  private

  def send_admin_notification_if_due(journey_configuration, now)
    close_at = journey_configuration.close_at&.in_time_zone("London")
    return unless close_at.present?

    close_at_seconds = close_at.to_i
    due_for_notification_at = [close_at_seconds - 7.days.to_i, close_at_seconds - 2.days.to_i]

    due_for_notification_at.each do |notification_time|
      next unless notification_time.between?(now - 1.minute, now)

      DfeSignIn::User.admin.not_deleted.find_each do |admin_user|
        AdminMailer.service_closing_soon(admin_user.email, journey_name: journey_configuration.journey.journey_name, close_at: close_at).deliver_now
      end
    end
  end
end
