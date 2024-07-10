require "rails_helper"

RSpec.describe Importers::EligibleFeProviders do
  subject { described_class.new(file:, academic_year:) }

  let(:academic_year) { AcademicYear.current }
  let(:file) { Tempfile.new }
  let(:correct_headers) { described_class.headers.join(",") + "\n" }

  def to_row(hash)
    [
      hash[:ukprn],
      hash[:max_award_amount],
      hash[:lower_award_amount]
    ].join(",") + "\n"
  end

  describe "#call" do
    context "when incorrect headers" do
      before do
        file.write "incorrect,headers,here,here"
        file.close
      end

      it "has errors" do
        subject.call

        expect(subject.errors).to be_present
        expect(subject.errors[:file]).to include("Incorrect headers")
      end
    end

    context "when csv has no rows" do
      before do
        file.write correct_headers
        file.close
      end

      it "has no errors" do
        subject.call

        expect(subject.errors).to be_empty
      end

      it "does not add any any records" do
        expect { subject.call }.not_to change { EligibleFeProvider.count }
      end

      context "when there are existing records" do
        before do
          create(:eligible_fe_provider)
          create(:eligible_fe_provider, academic_year: AcademicYear.next)
        end

        it "deletes existing records for academic year" do
          expect { subject.call }.to change { EligibleFeProvider.count }.to(1)
        end
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
        expect { subject.call }.to change { EligibleFeProvider.count }.by(3)
      end

      context "when there are existing records" do
        before do
          create(:eligible_fe_provider)
          create(:eligible_fe_provider, academic_year: AcademicYear.next)
        end

        it "deletes them with new records" do
          expect { subject.call }.to change { EligibleFeProvider.count }.by(2)
        end
      end
    end
  end
end
