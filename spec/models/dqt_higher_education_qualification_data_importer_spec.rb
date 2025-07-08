require "rails_helper"

RSpec.describe DqtHigherEducationQualificationDataImporter do
  subject { described_class.new(file) }

  let(:file) { Tempfile.new }
  let(:correct_headers) { described_class.mandatory_headers.join(",") + "\n" }
  let(:file_upload) { create(:file_upload, :not_completed_processing, target_data_model: DqtHigherEducationQualification.to_s) }

  def to_row(hash)
    [
      hash[:teacher_reference_number],
      "#{hash[:date_of_birth]}T00:00:00",
      hash[:national_insurance_number],
      hash[:subject_code],
      hash[:description]
    ].join(",") + "\n"
  end

  describe "#run" do
    context "when incorrect headers" do
      before do
        file.write "incorrect,headers,here,here"
        file.close
      end

      it "has errors" do
        subject.run

        expect(subject.errors).to be_present
        expect(subject.errors).to include("The selected file is missing some expected columns: trn, date_of_birth, nino, subject_code, description")
      end
    end

    context "when csv has no rows" do
      before do
        file.write correct_headers
        file.close
      end

      it "has no errors" do
        subject.run

        expect(subject.errors).to be_empty
      end

      it "does not add any any records" do
        expect { subject.run }.not_to change { DqtHigherEducationQualification.count }
      end

      context "when there are existing records" do
        before do
          create(:dqt_higher_education_qualification)
        end

        it "does not purge any records" do
          expect { subject.run }.not_to change { DqtHigherEducationQualification.count }
        end
      end
    end

    context "with valid no duplicates" do
      before do
        file.write correct_headers

        3.times do
          file.write to_row(attributes_for(:dqt_higher_education_qualification))
        end

        file.close
      end

      it "imports new records" do
        expect { subject.run }.to change { DqtHigherEducationQualification.count }.from(0).to(3)
      end

      context "when there are existing records" do
        before do
          create_list(:dqt_higher_education_qualification, 2)
        end

        it "adds the new records" do
          expect { subject.run }.to change { DqtHigherEducationQualification.count }.from(2).to(5)
        end
      end
    end

    context "when the some new records are duplicates" do
      let(:record_1) { attributes_for(:dqt_higher_education_qualification) }
      let(:record_2) { attributes_for(:dqt_higher_education_qualification) }
      let(:record_3) { attributes_for(:dqt_higher_education_qualification) }

      before do
        create(
          :dqt_higher_education_qualification,
          teacher_reference_number: record_1[:teacher_reference_number],
          date_of_birth: record_1[:date_of_birth],
          subject_code: record_1[:subject_code]
        )

        create(
          :dqt_higher_education_qualification,
          teacher_reference_number: record_2[:teacher_reference_number],
          date_of_birth: record_2[:date_of_birth],
          subject_code: record_2[:subject_code]
        )

        file.write correct_headers

        [record_1, record_2, record_3].each do |record|
          file.write to_row(record)
        end

        file.close
      end

      it "adds the non-duplicate record" do
        expect { subject.run }.to change { DqtHigherEducationQualification.count }.from(2).to(3)

        expect(DqtHigherEducationQualification.all.map(&:teacher_reference_number)).to contain_exactly(
          record_1[:teacher_reference_number],
          record_2[:teacher_reference_number],
          record_3[:teacher_reference_number]
        )
      end
    end
  end
end
