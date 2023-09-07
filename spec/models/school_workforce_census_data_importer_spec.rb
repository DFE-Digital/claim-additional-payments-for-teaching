require "rails_helper"

RSpec.describe SchoolWorkforceCensusDataImporter do
  let(:file) do
    tempfile = Tempfile.new
    tempfile.write(csv)
    tempfile.rewind
    tempfile
  end

  describe "#new" do
    subject { described_class.new(file) }

    context "The CSV is valid and has all the correct data" do
      let(:csv) do
        <<~CSV
          1234567,,,,Design and Technlogy - Textiles,,,
          ,,,,,,,,,,,,,,,
        CSV
      end

      it "has no errors and parses the CSV" do
        expect(subject.errors).to be_empty
        expect(subject.rows.count).to eq(2)
      end
    end

    context "The CSV is valid and has rows with TRN as NULL" do
      let(:csv) do
        <<~CSV
          NULL,,,,Design and Technlogy - Textiles,,,
          ,,,,,,,,,,,,,,,
        CSV
      end

      it "has no errors and parses the CSV" do
        expect(subject.errors).to be_empty
        expect(subject.rows.count).to eq(2)
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
          1234567,1234567,Full time,19,Design and Technlogy - Textiles,DTT,34,
          ,,,,,,,,,,,,,,,
        CSV
      end

      it "has no errors and parses the CSV" do
        expect(subject.errors).to be_empty
        expect(subject.rows.count).to eq(2)
      end
    end
  end

  describe "#run" do
    let!(:existing_census_entry) { create(:school_workforce_census, :early_career_payments_matched) }
    let(:csv) do
      <<~CSV
        1234567,1234567,Full time,19,Design and Technlogy - Textiles,DTT,34,
        NULL,,,,Design and Technlogy - Textiles,,,
        ,,,,,,,,,,,,,,,
      CSV
    end

    subject { described_class.new(file).run }

    context "no errors" do
      it "imports all rows with TRNS" do
        subject
        expect(SchoolWorkforceCensus.find_by_teacher_reference_number("1234567")).to be_present
      end

      it "skips rows with TRNS as NULL" do
        subject
        expect(SchoolWorkforceCensus.count).to eq(1)
      end

      it "skips empty rows" do
        subject
        expect(SchoolWorkforceCensus.count).to eq(1)
      end

      it "deletes all old rows before importing" do
        subject
        expect(SchoolWorkforceCensus.find_by_id(existing_census_entry.id)).to be_nil
      end
    end

    context "any row throws and error on save" do
      let(:csv) do
        <<~CSV
          1234567,1234567,Full time,19,Design and Technlogy - Textiles,DTT,34,
          ,,,,,,,,,,,,,,,
        CSV
      end

      it "delete all entries so it can be uploaded again" do
        allow(SchoolWorkforceCensus).to receive(:insert_all).and_raise(ActiveRecord::RecordInvalid)

        expect { subject }.to raise_error(ActiveRecord::RecordInvalid)
        expect(SchoolWorkforceCensus.find_by_id(existing_census_entry.id)).not_to be_present
      end
    end
  end
end
