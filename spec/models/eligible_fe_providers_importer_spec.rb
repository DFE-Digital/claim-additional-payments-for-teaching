require "rails_helper"

RSpec.describe EligibleFeProvidersImporter do
  subject { described_class.new(file, academic_year) }

  let(:academic_year) { AcademicYear.current }
  let(:file) { Tempfile.new }
  let(:correct_headers) { described_class.mandatory_headers.join(",") + "\n" }
  let(:file_upload) { create(:file_upload, :not_completed_processing, target_data_model: EligibleFeProvider.to_s, academic_year: AcademicYear.current.to_s) }

  def to_row(hash)
    [
      hash[:ukprn],
      hash[:max_award_amount],
      hash[:lower_award_amount]
    ].join(",") + "\n"
  end

  describe "#run" do
    context "when incorrect headers" do
      before do
        file.write "incorrect,headers,here,here"
        file.close
      end

      it "has errors" do
        subject.run(file_upload.id)

        expect(subject.errors).to be_present
        expect(subject.errors).to include("The selected file is missing some expected columns: ukprn, max_award_amount, lower_award_amount, primary_key_contact_email_address")
      end
    end

    context "when csv has no rows" do
      before do
        file.write correct_headers
        file.close
      end

      it "has no errors" do
        subject.run(file_upload.id)

        expect(subject.errors).to be_empty
      end

      it "does not add any any records" do
        expect { subject.run(file_upload.id) }.not_to change { EligibleFeProvider.count }
      end

      context "when there are existing records" do
        before do
          create(:eligible_fe_provider)
          create(:eligible_fe_provider, academic_year: AcademicYear.next)
        end

        it "does not purge any records" do
          expect { subject.run(file_upload.id) }.not_to change { EligibleFeProvider.count }
        end
      end
    end

    context "with extra empty rows" do
      before do
        file.write correct_headers

        file.write(described_class.mandatory_headers.map { nil }.join(",") + "\n")

        3.times do
          file.write to_row(attributes_for(:eligible_fe_provider))
        end

        file.write(described_class.mandatory_headers.map { nil }.join(",") + "\n")

        file.close
      end

      it "ignores empty rows" do
        expect { subject.run(file_upload.id) }.to change { EligibleFeProvider.count }.by(3)
      end

      it "does not raise errors" do
        expect { subject.run(file_upload.id) }.not_to raise_error
      end

      it "returns correct rows_with_data_count" do
        subject.run(file_upload.id)

        expect(subject.rows_with_data_count).to eql(3)
      end
    end

    context "with valid data" do
      before do
        file.write correct_headers

        3.times do
          file.write to_row(attributes_for(:eligible_fe_provider))
        end

        file.close
      end

      it "imports new records" do
        expect { subject.run(file_upload.id) }.to change { EligibleFeProvider.count }.by(3)
      end

      context "when there are existing records" do
        before do
          create(:eligible_fe_provider)
          create(:eligible_fe_provider, academic_year: AcademicYear.next)
        end

        it "imports new records, keeps existing and returns the latest" do
          expect { subject.run(file_upload.id) }.to change { EligibleFeProvider.count }.from(2).to(5)

          expect(EligibleFeProvider.by_academic_year(academic_year).count).to eq(1)
          file_upload.completed_processing!
          expect(EligibleFeProvider.by_academic_year(academic_year).count).to eq(3)
        end
      end
    end

    context "when currency values has GBP symbols and thousand separators" do
      before do
        file.write correct_headers

        3.times do
          file.write to_row(attributes_for(:eligible_fe_provider).merge(max_award_amount: '"£6,000"', lower_award_amount: '"£3,000"'))
        end

        file.close
      end

      it "ignores superfluous characters and imports new records" do
        expect { subject.run(file_upload.id) }.to change { EligibleFeProvider.count }.by(3)
        expect(EligibleFeProvider.pluck(:max_award_amount).uniq).to eql([6_000])
        expect(EligibleFeProvider.pluck(:lower_award_amount).uniq).to eql([3_000])
      end

      context "when there are existing records" do
        before do
          create(:eligible_fe_provider, max_award_amount: 5_000, lower_award_amount: 2_000)
          create(:eligible_fe_provider, academic_year: AcademicYear.next)
        end

        it "imports new records, keeps existing and returns the latest" do
          expect { subject.run(file_upload.id) }.to change { EligibleFeProvider.count }.from(2).to(5)

          expect(EligibleFeProvider.by_academic_year(academic_year).count).to eq(1)
          expect(EligibleFeProvider.by_academic_year(academic_year).pluck(:max_award_amount).uniq.sort).to eql([5_000])
          expect(EligibleFeProvider.by_academic_year(academic_year).pluck(:lower_award_amount).uniq.sort).to eql([2_000])

          file_upload.completed_processing!
          expect(EligibleFeProvider.by_academic_year(academic_year).count).to eq(3)
          expect(EligibleFeProvider.by_academic_year(academic_year).pluck(:max_award_amount).uniq.sort).to eql([6_000])
          expect(EligibleFeProvider.by_academic_year(academic_year).pluck(:lower_award_amount).uniq.sort).to eql([3_000])
        end
      end
    end

    context "when file has illegal encoding" do
      let(:file) { File.open(file_fixture("eligible_fe_providers_illegal_encoding.csv")) }

      it "ignores superfluous characters and imports new records" do
        expect { subject.run(file_upload.id) }.to change { EligibleFeProvider.count }.by(10)
        expect(EligibleFeProvider.pluck(:max_award_amount).uniq.sort).to eql([4_000, 5_000, 6_000])
        expect(EligibleFeProvider.pluck(:lower_award_amount).uniq.sort).to eql([2_000, 2_500, 3_000])
      end
    end
  end
end
