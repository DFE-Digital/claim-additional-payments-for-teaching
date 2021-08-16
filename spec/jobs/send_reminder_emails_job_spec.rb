require "rails_helper"

RSpec.describe SendReminderEmailsJob do
  let(:count) { [*1..5].sample }
  let(:reminders) { create_list(:reminder, count, email_verified: true) }
  before do
    # these should not send
    create(:reminder, email_verified: false)
    create(:reminder, email_verified: true, email_sent_at: Time.now)
  end

  describe "#perform" do
    it "sends correct email to correct addresses" do
      # reminder emails to be sent have blank sent_at's
      reminders.each do |reminder|
        expect(reminder.email_sent_at).to eq(nil)
      end

      # perform job
      expect {
        perform_enqueued_jobs do
          subject.perform("2021/2022")
        end
      }.to change { ActionMailer::Base.deliveries.count }.by(count)

      # check email body is correct
      reminder_email = ActionMailer::Base.deliveries.last.body.to_s
      expect(reminder_email).to include("Dear #{reminders.last.full_name},\n\nThe 2021/2022 early-career payment window is now open.")

      # reminder emails once sent have sent_at's
      reminders.each do |reminder|
        expect(reminder.reload.email_sent_at).to_not eq(nil)
      end
    end
  end
end
