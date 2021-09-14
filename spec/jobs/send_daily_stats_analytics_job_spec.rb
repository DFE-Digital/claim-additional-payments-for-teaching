require "rails_helper"

RSpec.describe SendDailyStatsAnalyticsJob do
  describe "#perform" do
    let(:file_name) { "daily-stats/daily-stats-analytics_#{Date.yesterday.strftime("%Y%m%d")}.csv" }

    before do
      allow(SendAnalyticsCsv).to receive(:new).with(
        query: ClaimStats::Daily,
        file_name: file_name
      ).and_return(
        double("SendAnalyticsCsv", call: true)
      )
    end

    it "runs without error" do
      expect {
        perform_enqueued_jobs do
          SendDailyStatsAnalyticsJob.new.perform
        end
      }.to_not raise_error
    end
  end
end
