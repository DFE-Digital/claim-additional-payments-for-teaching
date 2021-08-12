class SendRemindersJob < ApplicationJob
  def perform
    emails.each do |email|
      
    end
  end

  private

  def emails
    @emails ||= Reminder.not_yet_sent
  end
end
