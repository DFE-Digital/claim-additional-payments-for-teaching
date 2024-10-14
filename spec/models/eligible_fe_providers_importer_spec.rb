require "rails_helper"

RSpec.describe EligibleFeProvidersImporter do
  subject { described_class.new(file, academic_year) }

  let(:academic_year) { AcademicYear.current }
  let(:file) { Tempfile.new }
  let(:correct_headers) { described_class.mandatory_headers.join(",") + "\n" }

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
        subject.run

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
        subject.run

        expect(subject.errors).to be_empty
      end

      it "does not add any any records" do
        expect { subject.run }.not_to change { EligibleFeProvider.count }
      end

      context "when there are existing records" do
        before do
          create(:eligible_fe_provider)
          create(:eligible_fe_provider, academic_year: AcademicYear.next)
        end

        it "deletes existing records for academic year" do
          expect { subject.run }.to change { EligibleFeProvider.count }.to(1)
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
        expect { subject.run }.to change { EligibleFeProvider.count }.by(3)
      end

      it "does not raise errors" do
        expect { subject.run }.not_to raise_error
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
        expect { subject.run }.to change { EligibleFeProvider.count }.by(3)
      end

      context "when there are existing records" do
        before do
          create(:eligible_fe_provider)
          create(:eligible_fe_provider, academic_year: AcademicYear.next)
        end

        it "deletes them with new records" do
          expect { subject.run }.to change { EligibleFeProvider.count }.by(2)
        end
      end
    end
  end
end
