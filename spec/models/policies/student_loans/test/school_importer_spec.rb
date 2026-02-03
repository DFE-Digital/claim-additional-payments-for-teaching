require "rails_helper"

RSpec.describe Policies::StudentLoans::Test::SchoolImporter do
  describe "::import!" do
    it "runs the importer" do
      expect_any_instance_of(described_class).to receive(:import!)
      described_class.import!
    end
  end

  describe "#import!" do
    it "creates the school records" do
      expect {
        subject.import!
      }.to change(School, :count).by(2)
    end
  end
end
