require "rails_helper"

RSpec.describe TeachersPensionsServiceImporter do
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
        Teacher reference number,NINO,Start Date,End Date,Annual salary,Monthly pay,N/A,LA URN,School URN
        1234567,ZX043155C,01/09/2019,30/09/2019,24373,2031.08,5016,383,4026
      CSV
    end

    it "has no errors and parses the CSV" do
      subject.run
      expect(subject.errors).to be_empty

      expect(subject.rows.count).to eq(1)
      expect(subject.rows.first["Teacher reference number"]).to eq("1234567")
      expect(subject.rows.first["End Date"]).to eq("30/09/2019")
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
        Teacher reference number,Start Date,End Date,Annual salary,Monthly pay,N/A,LA URN,School URN
        1234567,ZX043155C,01/09/2019,30/09/2019,24373,2031.08,5016,383,4026,
      CSV
    end

    it "populates its errors" do
      expect(subject.errors).to eq(["The selected file is missing some expected columns: NINO"])
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
        Teacher reference number,NINO,Start Date,End Date,Annual salary,Monthly pay,N/A,LA URN,School URN
        1234567,ZX043155C,01/09/2019,30/09/2019,24373,2031.08,5016,383,4026,
      CSV
    end

    it "has no errors and parses the CSV" do
      expect(subject.errors).to be_empty

      expect(subject.rows.count).to eq(1)
      expect(subject.rows.first["Teacher reference number"]).to eq("1234567")
    end
  end

  context "The CSV contains duplicates" do
    let(:csv) do
      <<~CSV
        Teacher reference number,NINO,Start Date,End Date,Annual salary,Monthly pay,N/A,LA URN,School URN
        1234567,ZX043155C,01/09/2019,30/09/2019,24373,2031.08,5016,383,4026
        1234567,ZX043155C,01/09/2019,30/09/2019,24373,2031.08,5016,383,4026
      CSV
    end

    it "has no errors and parses the CSV" do
      subject.run
      expect(subject.errors).to eq(["The Teachers Pensions Service record with TRN 1234567 with StartDate 2019-09-01 is repeated at line 2"])
      expect(subject.run).to be_falsey

      expect(subject.rows.first["Teacher reference number"]).to eq("1234567")
      expect(subject.rows.first["End Date"]).to eq("30/09/2019")
    end
  end

  context "The CSV contains data for entire claim year for single TRN" do
    let(:csv) do
      <<~CSV
        Teacher reference number,NINO,Start Date,End Date,Annual salary,Monthly pay,N/A,LA URN,School URN
        1234567,ZX043155C,01/04/2020,31/12/2021,24373,2031.08,5016,383,4026
      CSV
    end

    it "has no errors and parses the CSV" do
      subject.run

      expect(subject.rows.first["Teacher reference number"]).to eq("1234567")
      expect(subject.rows.first["End Date"]).to eq("31/12/2021")
    end
  end

  context "The CSV contains data for first two months of the current claim year" do
    let(:csv) do
      <<~CSV
        Teacher reference number,NINO,Start Date,End Date,Annual salary,Monthly pay,N/A,LA URN,School URN
        1234567,ZX043155C,01/07/2021,01/09/2021,24373,2031.08,5016,383,4026
      CSV
    end

    it "has no errors and parses the CSV" do
      subject.run

      expect(subject.rows.first["Teacher reference number"]).to eq("1234567")
      expect(subject.rows.first["End Date"]).to eq("01/09/2021")
    end
  end
end
