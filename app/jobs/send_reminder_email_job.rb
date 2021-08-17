class SendReminderEmailJob < ApplicationJob
  def perform(reminder, year)
    ReminderMailer.reminder(reminder, year).deliver_now
    reminder.update!(email_sent_at: Time.now)
  end
end
