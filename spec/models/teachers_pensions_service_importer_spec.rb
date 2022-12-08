require "rails_helper"

RSpec.describe TeachersPensionsServiceImporter do
  subject { described_class.new(file) }

  let(:file) do
    tempfile = Tempfile.new
    tempfile.write(csv)
    tempfile.rewind
    tempfile
  end

  context "The CSV is valid and has all the correct data" do
    let(:csv) do
      <<~CSV
        Teacher reference number,NINO,Start Date,End Date,Annual salary,Monthly pay,N/A,LA URN,School URN
        12345672,ZX043155C,01/09/2019,30/09/2019,24373,2031.08,5016,383,4026
      CSV
    end

    it "has no errors and parses the CSV" do
      expect { subject.run }.to(change(TeachersPensionsService, :count).by(1))
      expect(subject.errors).to be_empty

      expect(subject.rows.count).to eq(1)
      expect(subject.rows.first["Teacher reference number"]).to eq("12345672")
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
        12345672,ZX043155C,01/09/2019,30/09/2019,24373,2031.08,5016,383,4026,
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
        12345672,ZX043155C,01/09/2019,30/09/2019,24373,2031.08,5016,383,4026,
      CSV
    end

    it "has no errors and parses the CSV" do
      expect(subject.errors).to be_empty

      expect(subject.rows.count).to eq(1)
      expect(subject.rows.first["Teacher reference number"]).to eq("12345672")
    end
  end

  context "The CSV contains duplicates" do
    let(:csv) do
      <<~CSV
        Teacher reference number,NINO,Start Date,End Date,Annual salary,Monthly pay,N/A,LA URN,School URN
        12345672,ZX043155C,01/09/2019,30/09/2019,24373,2031.08,5016,383,4026
        12345672,ZX043155C,01/09/2019,30/09/2019,24373,2031.08,5016,383,4026
        12345681,ZX043155C,01/09/2020,30/09/2020,24373,2031.08,5016,383,4026
        12345681,ZX043155C,01/09/2020,30/09/2020,24373,2031.08,5016,383,4026
      CSV
    end

    it "excludes duplicates and parses the CSV" do
      expect { subject.run }.to(change(TeachersPensionsService, :count).by(2))

      expect(subject.errors).to be_empty
      expect(subject.rows.count).to eq(4)
      expect(TeachersPensionsService.first[:teacher_reference_number]).to eq("1234567")
      expect(TeachersPensionsService.first[:gender_digit]).to eq(2)
      expect(TeachersPensionsService.first[:start_date].to_date).to eq(Date.new(2019, 9, 1))
      expect(TeachersPensionsService.second[:teacher_reference_number]).to eq("1234568")
      expect(TeachersPensionsService.second[:gender_digit]).to eq(1)
      expect(TeachersPensionsService.second[:start_date].to_date).to eq(Date.new(2020, 9, 1))
    end
  end

  context "The CSV contains data for entire claim year for single TRN" do
    let(:csv) do
      <<~CSV
        Teacher reference number,NINO,Start Date,End Date,Annual salary,Monthly pay,N/A,LA URN,School URN
        12345672,ZX043155C,01/04/2020,31/12/2021,24373,2031.08,5016,383,4026
      CSV
    end

    it "has no errors and parses the CSV" do
      expect { subject.run }.to(change(TeachersPensionsService, :count).by(1))

      expect(subject.rows.first["Teacher reference number"]).to eq("12345672")
      expect(subject.rows.first["End Date"]).to eq("31/12/2021")
    end
  end

  context "The CSV contains data for first two months of the current claim year" do
    let(:csv) do
      <<~CSV
        Teacher reference number,NINO,Start Date,End Date,Annual salary,Monthly pay,N/A,LA URN,School URN
        12345672,ZX043155C,01/07/2021,01/09/2021,24373,2031.08,5016,383,4026
      CSV
    end

    it "has no errors and parses the CSV" do
      expect { subject.run }.to(change(TeachersPensionsService, :count).by(1))

      expect(subject.rows.first["Teacher reference number"]).to eq("12345672")
      expect(subject.rows.first["End Date"]).to eq("01/09/2021")
    end
  end
end
