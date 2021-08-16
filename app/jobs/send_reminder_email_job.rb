class SendReminderEmailJob < ApplicationJob
  def perform(reminder, year)
    ReminderMailer.reminder(reminder, year).deliver_now
  end
end
