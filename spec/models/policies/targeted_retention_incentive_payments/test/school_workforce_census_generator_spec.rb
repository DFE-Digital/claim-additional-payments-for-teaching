require "rails_helper"

RSpec.describe Policies::TargetedRetentionIncentivePayments::Test::SchoolWorkforceCensusGenerator do
  before do
    stub_const(
      "Policies::TargetedRetentionIncentivePayments::Test::UserPersona::FILE",
      file_fixture("targeted_retention_incentive_payments_personas.csv")
    )

    create(
      :school,
      name: "Eligible school"
    )

    create(
      :school,
      name: "Ineligible school"
    )
  end

  describe "::import!" do
    it "persists test school workforce census data" do
      expect {
        perform_enqueued_jobs do
          described_class.import!
        end
      }.to change(SchoolWorkforceCensus, :count).by(5)
    end
  end

  describe "#data" do
    it "only includes eligible data" do
      expect(subject.data.size).to eql 5
    end
  end

  describe "#to_csv" do
    it "returns correct output" do
      expected = <<STRING.delete(" ")
       3013047,1,,,Computing,,
       3013048,1,,,Computing,,
       3013050,1,,,Computing,,
       3013053,1,,,Computing,,
       3013059,1,,,Computing,,
STRING

      expect(subject.to_csv.to_s(write_headers: false)).to eql expected
    end
  end

  describe "#to_file" do
    it "writes csv to disk" do
      expected = <<STRING.delete(" ")
       3013047,1,,,Computing,,
       3013048,1,,,Computing,,
       3013050,1,,,Computing,,
       3013053,1,,,Computing,,
       3013059,1,,,Computing,,
STRING

      file = described_class.to_file

      expect(file.read).to eql(expected)
    end
  end
end
