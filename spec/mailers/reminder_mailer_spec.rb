require "rails_helper"

RSpec.describe ReminderMailer do
  let(:reminder) {
    create(:reminder, :with_fe_reminder)
  }

  describe "#reminder_set" do
    it "includes unsubscribe_url in personalisation" do
      mail = described_class.reminder_set(reminder)

      expect(mail.personalisation[:unsubscribe_url]).to eql("https://www.example.com/further-education-payments/unsubscribe/reminders/#{reminder.id}")
    end
  end
end
