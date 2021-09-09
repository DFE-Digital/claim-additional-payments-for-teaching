require "rails_helper"

RSpec.describe SendAnalyticsCsv do
  subject { SendAnalyticsCsv }
  describe "#call" do
    let(:query) { ClaimDecision }
    let(:file_name) { "test.csv" }
    let(:uploader) { instance_double("Upload", call: true) }

    before do
      allow(Upload).to receive(:new).and_return(uploader)
    end

    it "runs without error" do
      expect {
        subject.new(
          query: query,
          file_name: file_name
        ).call
      }.to_not raise_error
    end
  end
end
