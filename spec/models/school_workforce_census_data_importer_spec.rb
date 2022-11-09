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
          TRN,GeneralSubjectDescription,2nd,3rd,4th,5th,6th,7th,8th,9th,10th,11th,12th,13th,14th,15th
          1234567,Design and Technlogy - Textiles,,,,,,,,,,,,,,
          ,,,,,,,,,,,,,,,
        CSV
      end

      it "has no errors and parses the CSV" do
        expect(subject.errors).to be_empty
        expect(subject.rows.count).to eq(2)
        expect(subject.rows.first["TRN"]).to eq("1234567")
        expect(subject.rows.first["GeneralSubjectDescription"]).to eq("Design and Technlogy - Textiles")
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
          TRN,GeneralSubjectDescription,3rd,4th,5th,6th,7th,8th,9th,10th,11th,12th,13th,14th,15th
          1234567,Design and Technlogy - Textiles,,,,,,,,,,,,,
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
          TRN,GeneralSubjectDescription,2nd,3rd,4th,5th,6th,7th,8th,9th,10th,11th,12th,13th,14th,15th
          1234567,Design and Technlogy - Textiles,,,,,,,,,,,,,,
        CSV
      end

      it "has no errors and parses the CSV" do
        expect(subject.errors).to be_empty
        expect(subject.rows.count).to eq(1)
        expect(subject.rows.first["TRN"]).to eq("1234567")
      end
    end
  end

  describe "#run" do
    let!(:existing_census_entry) { create(:school_workforce_census, :early_career_payments_matched) }
    let(:csv) do
      <<~CSV
        TRN,GeneralSubjectDescription,2nd,3rd,4th,5th,6th,7th,8th,9th,10th,11th,12th,13th,14th,15th
        1234567,Design and Technlogy - Textiles,,,,,,,,,,,,,,
        ,,,,,,,,,,,,,,,
      CSV
    end

    subject { described_class.new(file).run }

    context "no errors" do
      it "imports all rows with TRNS" do
        subject
        expect(SchoolWorkforceCensus.find_by_teacher_reference_number("1234567")).to be_present
      end

      it "imports all rows with TRNS with the correct subjects" do
        subject
        expect(SchoolWorkforceCensus.find_by_teacher_reference_number("1234567").subjects).to eq(["Design and Technlogy - Textiles"])
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

    context "use all 15 subjects" do
      let(:csv) do
        <<~CSV
          TRN,GeneralSubjectDescription,2nd,3rd,4th,5th,6th,7th,8th,9th,10th,11th,12th,13th,14th,15th
          1234567,Art and Design / Art,Commercial and Business Studies/Education/Management,Design and Technology - Graphics,English,Geography,Health and Social Care,History,Mathematics / Mathematical Development (Early Years),Media Studies,Music,Other Vocational Subject,Physical Education / Sports,Science,Sociology,Spanish
          ,,,,,,,,,,,,,,,
        CSV
      end

      it "imports all rows with TRNS with the correct subjects" do
        subject
        expect(SchoolWorkforceCensus.find_by_teacher_reference_number("1234567").subjects).to eq(["Art and Design / Art", "Commercial and Business Studies/Education/Management", "Design and Technology - Graphics", "English", "Geography", "Health and Social Care", "History", "Mathematics / Mathematical Development (Early Years)", "Media Studies", "Music", "Other Vocational Subject", "Physical Education / Sports", "Science", "Sociology", "Spanish"])
      end
    end

    context "any row throws and error on save" do
      let(:csv) do
        <<~CSV
          TRN,GeneralSubjectDescription,2nd,3rd,4th,5th,6th,7th,8th,9th,10th,11th,12th,13th,14th,15th
          1234567,Design and Technlogy - Textiles,,,,,,,,,,,,,,
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
