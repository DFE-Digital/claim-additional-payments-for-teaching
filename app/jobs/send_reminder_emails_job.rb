class SendReminderEmailsJob < ApplicationJob
  def perform(journey)
    Reminder.to_be_sent.by_journey(journey).find_each(batch_size: 100) do |reminder|
      SendReminderEmailJob.perform_later(reminder)
    end
  end
end
