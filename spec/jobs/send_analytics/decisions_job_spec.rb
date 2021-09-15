require "rails_helper"

RSpec.describe SendAnalytics::DecisionsJob do
  describe "#perform" do
    let(:date) { Date.yesterday }

    before do
      allow(::SendAnalytics::Decisions).to receive(:new).with(
        date: date
      ).and_return(
        instance_double("::SendAnalytics::Decisions", call: true)
      )
    end

    it "runs without error" do
      expect {
        perform_enqueued_jobs do
          SendAnalytics::DecisionsJob.new.perform
        end
      }.to_not raise_error
    end
  end
end
