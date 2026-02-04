require "rails_helper"

RSpec.describe Policies::StudentLoans::Test::UserPersona do
  describe "::all" do
    subject { described_class.all }

    it "returns an array of user personas defined in the CSV file" do
      expect(subject).to be_a(Array)
      expect(subject.count).to eq(2)
      expect(subject).to all(be_a(described_class))
    end
  end

  describe "::import!" do
    before do
      allow(Policies::StudentLoans::Test::SchoolImporter).to receive(:import!)
    end

    it "calls various importers" do
      described_class.import!

      expect(Policies::StudentLoans::Test::SchoolImporter).to have_received(:import!)
    end
  end

  describe "#initialize" do
    subject { described_class.new(csv_row) }

    let(:csv_row) do
      {
        "school_name" => "Test School",
        "first_name" => "John",
        "last_name" => "Smith",
        "date_of_birth" => "01/01/1990",
        "nino" => "AB123456C",
        "trn" => "1234567",
        "expected_result" => "eligible"
      }
    end

    it "maps row to attributes" do
      expect(subject.school_name).to eq("Test School")
      expect(subject.teacher_reference_number).to eq("1234567")
      expect(subject.first_name).to eq("John")
      expect(subject.last_name).to eq("Smith")
      expect(subject.date_of_birth).to eq("01/01/1990")
      expect(subject.national_insurance_number).to eq("AB123456C")
    end
  end
end
