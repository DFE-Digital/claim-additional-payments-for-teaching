require "rails_helper"

RSpec.describe AutomatedChecks::DqtReportCsv do
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
        dfeta text1,dfeta text2,dfeta trn,fullname,birthdate,dfeta ninumber,dfeta qtsdate,HESubject1Value,HESubject2Value,HESubject3Value,ITTSub1Value,ITTSub2Value,ITTSub3Value
        1234567,ABC12345,1234567,Fred Smith,23/8/1990,QQ123456C,23/8/2017,L200,,,G100,,
      CSV
    end

    it "has no errors and parses the CSV" do
      expect(subject.errors).to be_empty

      expect(subject.rows.count).to eq(1)
      expect(subject.rows.first["dfeta text2"]).to eq("ABC12345")
      expect(subject.rows.first["dfeta trn"]).to eq("1234567")
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
        dfeta text1,dfeta trn,fullname,birthdate,dfeta ninumber,HESubject1Value,HESubject2Value,HESubject3Value,ITTSub1Value,ITTSub2Value,ITTSub3Value
        1234567,ABC12345,1234567,Fred Smith,23/8/1990,QQ123456C,23/8/2017,L200,,,G100,,
      CSV
    end

    it "populates its errors" do
      expect(subject.errors).to eq(["The selected file is missing some expected columns: dfeta text2, dfeta qtsdate"])
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
        dfeta text1,dfeta text2,dfeta trn,fullname,birthdate,dfeta ninumber,dfeta qtsdate,HESubject1Value,HESubject2Value,HESubject3Value,ITTSub1Value,ITTSub2Value,ITTSub3Value
        1234567,ABC12345,1234567,Fred Smith,23/8/1990,QQ123456C,23/8/2017,L200,,,G100,,
      CSV
    end

    it "has no errors and parses the CSV" do
      expect(subject.errors).to be_empty

      expect(subject.rows.count).to eq(1)
      expect(subject.rows.first["dfeta text2"]).to eq("ABC12345")
    end
  end
end
