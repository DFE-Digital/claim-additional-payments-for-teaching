require "rails_helper"

RSpec.describe SendAnalytics::Decisions do
  subject { SendAnalytics::Decisions }
  describe "#call" do
    let(:uploader) { instance_double("Upload", call: true) }
    let(:date)    { Date.yesterday }

    before do
      allow(Upload).to receive(:new).and_return(uploader)
    end

    it "runs without error" do
      expect {
        subject.new(
          date: date
        ).call
      }.to_not raise_error
    end
  end
end
