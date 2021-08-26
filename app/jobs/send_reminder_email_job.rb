class SendReminderEmailJob < ApplicationJob
  def perform(reminder)
    ReminderMailer.reminder(reminder).deliver_now
    reminder.update!(email_sent_at: Time.now)
  end
end
