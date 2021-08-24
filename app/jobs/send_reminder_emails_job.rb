class SendReminderEmailsJob < ApplicationJob
  def perform
    reminders.find_each(batch_size: 100) do |reminder|
      SendReminderEmailJob.perform_later(reminder)
    end
  end

  private

  def reminders
    @reminders ||= Reminder.to_be_sent
  end
end
