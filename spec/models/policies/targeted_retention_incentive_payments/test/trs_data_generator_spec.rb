require "rails_helper"

RSpec.describe Policies::TargetedRetentionIncentivePayments::Test::TrsDataGenerator do
  before do
    stub_const(
      "Policies::TargetedRetentionIncentivePayments::Test::UserPersona::FILE",
      file_fixture("targeted_retention_incentive_payments_personas.csv")
    )

    create(:school, name: "Eligible school")
    create(:school, name: "Ineligible school")
  end

  describe "::data" do
    it "returns an array of TRS data records" do
      expect(described_class.data).to be_a(Array)
      expect(described_class.data.count).to eq(14)
    end

    it "generates correct data for each persona" do
      first_record = described_class.data.first

      expect(first_record[0]).to eq("3013047")
      expect(first_record[1]).to eq("Kenneth")
      expect(first_record[2]).to eq("Decerqueira")
      expect(first_record[3]).to eq("08/07/1965")
      expect(first_record[4]).to eq("AB400011A")
      expect(first_record[6]).to eq("Pass")
      expect(first_record[7]).to eq(:undergraduate_itt)
      expect(first_record[11]).to eq(false)
    end
  end

  describe "::to_csv" do
    it "generates correct headers" do
      expect(described_class.to_csv.headers).to eq(
        %w[
          teacher_reference_number
          first_name
          last_name
          date_of_birth
          national_insurance_number
          qts_date
          induction_status
          route_type
          itt_subject_1
          itt_start_date
          itt_qualification_type
          active_alert
        ]
      )
    end

    it "generates a CSV table" do
      expect(described_class.to_csv).to be_a(CSV::Table)
      expect(described_class.to_csv.count).to eq(14)
    end
  end

  describe "::to_file" do
    it "saves csv to disk" do
      file = described_class.to_file
      content = file.read

      expect(file).to be_a(Tempfile)
      expect(content).to include("teacher_reference_number,first_name,last_name")
      expect(content).to include("3013047")
    end

    it "accepts a custom file" do
      custom_file = Tempfile.new
      result = described_class.to_file(custom_file)

      expect(result).to eq(custom_file)
      expect(result.read).to include("teacher_reference_number")
    end
  end
end
