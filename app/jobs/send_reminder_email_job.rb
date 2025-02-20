class SendReminderEmailJob < ApplicationJob
  def perform(reminder)
    # TODO: Remove when the template is updated to support other journeys
    return unless [
      Journeys::AdditionalPaymentsForTeaching,
      Journeys::TargetedRetentionIncentivePayments
    ].include?(reminder.journey)

    ReminderMailer.reminder(reminder).deliver_now
    reminder.update!(email_sent_at: Time.now)
  end
end
