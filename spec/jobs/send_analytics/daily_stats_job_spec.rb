require "rails_helper"

RSpec.describe SendAnalytics::DailyStatsJob do
  describe "#perform" do
    let(:date) { Date.yesterday }

    before do
      allow(SendAnalytics::DailyStats).to receive(:new).with(
        date: date
      ).and_return(
        double("SendAnalytics::DailyStats", call: true)
      )
    end

    it "runs without error" do
      expect {
        perform_enqueued_jobs do
          SendAnalytics::DailyStatsJob.new.perform
        end
      }.to_not raise_error
    end
  end
end
