class SendRemindersJob < ApplicationJob
  def perform(reminder, year)
    ReminderMailer.reminder(reminder, year).send_now
  end
end
