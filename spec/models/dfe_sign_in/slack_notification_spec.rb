require "rails_helper"

RSpec.describe DfeSignIn::SlackNotification, type: :model do
  let(:user) { create(:dfe_signin_user) }
  let(:user_uuid) { user.id }

  describe "#initialize" do
    context "with a valid user UUID" do
      it "returns an instance" do
        expect(described_class.new(user_uuid)).to be_a(described_class)
      end
    end

    context "without a valid user UUID" do
      let(:user_uuid) { "test" }

      it "raises an exception" do
        expect { described_class.new(user_uuid) }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe "#run" do
    before do
      allow(ENV).to receive(:fetch).with("ENVIRONMENT_NAME").and_return("test")
      allow(ENV).to receive(:fetch).with("DFE_SIGN_IN_SLACK_NOTIFICATION_WEBHOOK_URL").and_return("test")
    end

    it "sends a notification" do
      expect_any_instance_of(Slack::Notifier).to receive(:ping).with("A new user has been granted access to the Claim admin panel: #{user.given_name} #{user.family_name} - #{user.organisation_name} (#{user.email})")
      described_class.new(user_uuid).run
    end
  end
end
