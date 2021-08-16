class SendReminderEmailsJob < ApplicationJob
  def perform(year)
    reminders.each do |reminder|
      ReminderEmailJob.perform_later(reminder, year)
    end
  end

  private

  def reminders
    @reminders ||= Reminder.not_yet_sent
  end
end
