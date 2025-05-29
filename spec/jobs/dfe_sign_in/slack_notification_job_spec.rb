require "rails_helper"

RSpec.describe DfeSignIn::SlackNotificationJob do
  it { expect(described_class.new).to be_an(ApplicationJob) }

  describe "#perform" do
    subject(:job) { described_class.new }

    let(:user_uuid) { "test" }
    let(:notification) { double("DfeSignIn::SlackNotification", run: true) }

    it "sends the Slack notification" do
      expect(DfeSignIn::SlackNotification).to receive(:new).with(user_uuid).and_return(notification)
      expect(notification).to receive(:run)
      job.perform(user_uuid)
    end
  end
end
