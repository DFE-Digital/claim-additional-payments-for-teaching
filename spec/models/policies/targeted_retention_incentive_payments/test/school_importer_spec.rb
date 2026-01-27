require "rails_helper"

RSpec.describe Policies::TargetedRetentionIncentivePayments::Test::SchoolImporter do
  describe ".run" do
    it "runs the importer" do
      expect_any_instance_of(described_class).to receive(:import!)
      described_class.run
    end
  end

  describe "#import!" do
    it "de-duplicates and creates the school records" do
      expect(School.count).to eq(0)
      subject.import!
      expect(School.count).to eq(2)
    end
  end
end
