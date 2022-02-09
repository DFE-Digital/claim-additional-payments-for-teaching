require "rails_helper"

RSpec.describe SchoolWorkforceCensusDataImporter do
  let(:file) do
    tempfile = Tempfile.new
    tempfile.write(csv)
    tempfile.rewind
    tempfile
  end

  subject { described_class.new(file) }

  context "The CSV is valid and has all the correct data" do
    let(:csv) do
      <<~CSV
        TRN,"GeneralSubjectDescription, 1st occurance",2nd,3rd,4th,5th,6th,7th,8th,9th
        1234567,Design and Technlogy - Textiles,,,,,,,,
      CSV
    end

    it "has no errors and parses the CSV" do
      expect(subject.errors).to be_empty

      expect(subject.rows.count).to eq(1)
      expect(subject.rows.first["TRN"]).to eq("1234567")
      expect(subject.rows.first["GeneralSubjectDescription, 1st occurance"]).to eq("Design and Technlogy - Textiles")
    end
  end

  context "The CSV is malformed" do
    let(:csv) do
      <<~CSV
        "1","2","3" "
      CSV
    end

    it "populates its errors" do
      expect(subject.errors).to eq(["The selected file must be a CSV"])
    end
  end

  context "The CSV does not have the expected headers" do
    let(:csv) do
      <<~CSV
        TRN,"GeneralSubjectDescription, 1st occurance",3rd,4th,5th,6th,7th,8th,9th
        1234567,Design and Technlogy - Textiles,,,,,,,
      CSV
    end

    it "populates its errors" do
      expect(subject.errors).to eq(["The selected file is missing some expected columns: 2nd"])
    end
  end

  context "The CSV is not present" do
    let(:file) { nil }

    it "populates its errors" do
      expect(subject.errors).to eq(["Select a file"])
    end
  end

  context "The CSV contains a byte order mark (BOM)" do
    let(:file) do
      tempfile = Tempfile.new
      tempfile.write(byte_order_mark + csv)
      tempfile.rewind
      tempfile
    end
    let(:byte_order_mark) { "\xEF\xBB\xBF" }
    let(:csv) do
      <<~CSV
        TRN,"GeneralSubjectDescription, 1st occurance",2nd,3rd,4th,5th,6th,7th,8th,9th
        1234567,Design and Technlogy - Textiles,,,,,,,,
      CSV
    end

    it "has no errors and parses the CSV" do
      expect(subject.errors).to be_empty

      expect(subject.rows.count).to eq(1)
      expect(subject.rows.first["TRN"]).to eq("1234567")
    end
  end
end
