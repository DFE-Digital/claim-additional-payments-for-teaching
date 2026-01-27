require "rails_helper"

RSpec.describe Policies::TargetedRetentionIncentivePayments::Test::StriAwardsGenerator do
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

  describe "::data" do
    it "generates correct awards" do
      expected = [
        Policies::TargetedRetentionIncentivePayments::Award.new(school_urn: 1, award_amount: 6_000),
        Policies::TargetedRetentionIncentivePayments::Award.new(school_urn: 2, award_amount: 6_000)
      ]

      described_class.data.each_with_index do |record, index|
        expect(record).to have_attributes(expected[index].attributes)
      end
    end
  end

  describe "::to_csv" do
    it "generates correct headers" do
      expect(described_class.to_csv.headers).to eql(["school_urn", "award_amount"])
    end

    it "generates correct csv" do
      expected_output = <<STRING.delete(" ")
       1,6000.0
       2,6000.0
STRING

      expect(described_class.to_csv.to_s).to end_with(expected_output)
    end
  end

  describe "::to_file" do
    it "save csv to disk" do
      expected_output = <<STRING.delete(" ")
       school_urn,award_amount
       1,6000.0
       2,6000.0
STRING

      file = described_class.to_file
      expect(file.read).to eql(expected_output)
    end
  end
end
