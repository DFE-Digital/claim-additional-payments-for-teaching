require "rails_helper"

RSpec.describe SendEmailsAfterThreeWeeksJob do
  before do
    create_list(:claim, 2, :submitted, submitted_at: 21.days.ago)
    create_list(:claim, 2, :submitted, submitted_at: 40.days.ago)
    create_list(:claim, 2, :submitted, submitted_at: 3.days.ago)
    create_list(:claim, 2, :approved, submitted_at: 21.days.ago)
    create_list(:claim, 2)
  end

  describe "#perform" do
    it "sends the expected number of emails" do
      expect {
        perform_enqueued_jobs do
          SendEmailsAfterThreeWeeksJob.new.perform
        end
      }.to change { ActionMailer::Base.deliveries.count }.by(2)
    end
  end
end
