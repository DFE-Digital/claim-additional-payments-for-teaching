class SendReminderEmailJob < ApplicationJob
  def perform(reminder)
    # TODO: Remove when the template is updated to support other journeys
    return unless reminder.journey == Journeys::AdditionalPaymentsForTeaching

    ReminderMailer.reminder(reminder).deliver_now
    reminder.update!(email_sent_at: Time.now)
  end
end
