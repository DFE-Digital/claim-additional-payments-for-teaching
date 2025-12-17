require "rails_helper"

RSpec.describe Policies::TargetedRetentionIncentivePayments::Test::SchoolWorkforceCensusGenerator do
  before do
    create(
      :school,
      name: "Eligible school"
    )

    create(
      :school,
      name: "Ineligible school"
    )
  end

  describe "#data" do
    it "only includes eligible data" do
      expect(subject.data.size).to eql 5
    end
  end

  describe "#to_csv" do
    it "returns correct output" do
      expected = <<STRING.delete(" ")
       ,1,,,Computing,,
       ,1,,,Computing,,
       ,1,,,Computing,,
       ,1,,,Computing,,
       ,1,,,Computing,,
STRING

      expect(subject.to_csv.to_s(write_headers: false)).to eql expected
    end
  end

  describe "#to_file" do
    it "writes csv to disk" do
      expected = <<STRING.delete(" ")
       ,1,,,Computing,,
       ,1,,,Computing,,
       ,1,,,Computing,,
       ,1,,,Computing,,
       ,1,,,Computing,,
STRING

      file = described_class.to_file

      expect(file.read).to eql(expected)
    end
  end
end
