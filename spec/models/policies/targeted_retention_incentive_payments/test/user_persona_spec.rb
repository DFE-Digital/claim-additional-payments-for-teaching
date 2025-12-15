require "rails_helper"

RSpec.describe Policies::TargetedRetentionIncentivePayments::Test::UserPersona do
  describe ".all" do
    subject { described_class.all }

    it "returns an array of user personas defined in the CSV file" do
      expect(subject).to be_a(Array)
      expect(subject.count).to eq(14)
      expect(subject).to all(be_a(described_class))
    end
  end

  describe "#initialize" do
    subject { described_class.new(csv_row) }

    let(:csv_row) do
      {
        "School name" => school_name
      }
    end
    let(:school_name) { "test" }

    it "maps the school name" do
      expect(subject.school_name).to eq(school_name)
    end
  end
end
