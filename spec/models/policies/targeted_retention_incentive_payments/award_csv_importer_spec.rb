require "rails_helper"

RSpec.describe Policies::TargetedRetentionIncentivePayments::AwardCsvImporter do
  let(:csv_file) { File.new("spec/fixtures/files/targeted_retention_incentive_school_awards_good.csv") }
  let(:csv_file_with_bad_data) { File.new("spec/fixtures/files/targeted_retention_incentive_school_awards_bad.csv") }
  let(:csv_file_with_extra_columns) { File.new("spec/fixtures/files/targeted_retention_incentive_school_awards_additional_columns.csv") }
  let(:csv_file_without_headers) { File.new("spec/fixtures/files/targeted_retention_incentive_school_awards_no_headers.csv") }
  let(:not_a_csv_file) { File.new("spec/fixtures/local_authorities.yml") }

  let(:academic_year) { AcademicYear.current }
  let(:csv_data) { csv_file }

  describe "validations" do
    subject { described_class.new(academic_year: academic_year.to_s, csv_data: csv_data) }

    context "without a CSV file" do
      let(:csv_data) { nil }
      it { is_expected.not_to be_valid }
    end

    context "without an academic year" do
      let(:academic_year) { nil }
      it { is_expected.not_to be_valid }
    end

    context "with academic year and CSV file" do
      context "when the academic year is invalid" do
        let(:academic_year) { "invalid" }
        it { is_expected.not_to be_valid }
      end

      context "when the CSV file cannot be parsed" do
        let(:csv_data) { not_a_csv_file }
        it { is_expected.not_to be_valid }
      end

      context "when the CSV file has no headers" do
        let(:csv_data) { csv_file_without_headers }
        it { is_expected.not_to be_valid }
      end

      context "when the CSV file has extra columns" do
        let(:csv_data) { csv_file_with_extra_columns }
        it { is_expected.not_to be_valid }
      end

      context "when the CSV file has bad data" do
        let(:csv_data) { csv_file_with_bad_data }
        it { is_expected.not_to be_valid }
      end

      context "when both are correct" do
        it { is_expected.to be_valid }
      end
    end
  end

  describe ".process" do
    subject(:importer) { described_class.new(academic_year: academic_year.to_s, csv_data: csv_data) }

    context "when there are existing records" do
      let!(:old_award_same_academic_year) { create(:targeted_retention_incentive_payments_award, academic_year: academic_year) }
      let!(:old_award_other_academic_year) { create(:targeted_retention_incentive_payments_award, academic_year: academic_year - 1) }

      it "deletes the old data" do
        importer.process
        expect { old_award_same_academic_year.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it "does not delete data from other academic years" do
        importer.process
        expect { old_award_other_academic_year.reload }.not_to raise_error
      end

      it "populates the table with the CSV data" do
        importer.process
        expect(Policies::TargetedRetentionIncentivePayments::Award.where(academic_year: academic_year.to_s).count).to eq 8
      end

      it "skips rows where the award amount is zero" do
        importer.process
        expect(Policies::TargetedRetentionIncentivePayments::Award.where(award_amount: 0).count).to eq 0
      end

      context "when there are errors" do
        let(:csv_data) { csv_file_without_headers }

        it "returns false" do
          expect(importer.process).to be_falsey
        end

        it "does not delete the old records" do
          importer.process
          expect { old_award_same_academic_year.reload }.not_to raise_error
        end

        it "does not populate the table with the CSV data" do
          importer.process
          expect(Policies::TargetedRetentionIncentivePayments::Award.where(academic_year: academic_year.to_s).count).to eq 1
        end
      end
    end
  end
end
