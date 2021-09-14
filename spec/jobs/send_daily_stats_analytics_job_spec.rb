require "rails_helper"

RSpec.describe SendDecisionsAnalyticsJob do
  describe "#perform" do
    let(:file_name) { "decisions-analytics_#{Date.yesterday.strftime("%Y%m%d")}.csv" }

    before do
      allow(SendAnalyticsCsv).to receive(:new).with(
        query: Claim.yesterday,
        file_name: file_name
      ).and_return(
        double("SendAnalyticsCsv", call: true)
      )
    end

    it "runs without error" do
      expect {
        perform_enqueued_jobs do
          SendDecisionsAnalyticsJob.new.perform
        end
      }.to_not raise_error
    end
  end
end
