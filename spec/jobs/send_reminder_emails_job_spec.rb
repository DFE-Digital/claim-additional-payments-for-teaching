require "rails_helper"

RSpec.describe SendReminderEmailsJob do
  let(:count) { [*1..5].sample }
  before do
    # these should send
    create_list(:reminder, count, email_verified: true)
    # these should not send
    create(:reminder, email_verified: false)
    create(:reminder, email_verified: true, email_sent_at: Time.now)
  end

  describe "#perform" do
    it "sends the expected number of emails" do
      expect {
        perform_enqueued_jobs do
          subject.perform("2021/2022")
        end
      }.to change { ActionMailer::Base.deliveries.count }.by(count)
    end
  end
end
