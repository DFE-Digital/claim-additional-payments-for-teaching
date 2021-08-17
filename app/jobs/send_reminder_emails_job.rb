class SendReminderEmailsJob < ApplicationJob
  def perform(year)
    reminders.find_each(batch_size: 100) do |reminder|
      SendReminderEmailJob.perform_later(reminder, year)
    end
  end

  private

  def reminders
    @reminders ||= Reminder.not_yet_sent
  end
end
