require "rails_helper"

RSpec.describe Policies::TargetedRetentionIncentivePayments::Award do
  describe ".csv_for_academic_year" do
    let(:academic_year) { AcademicYear.current }
    let!(:award) { create(:targeted_retention_incentive_payments_award, academic_year: academic_year) }
    before { create(:targeted_retention_incentive_payments_award, academic_year: academic_year - 1) }

    subject(:csv) { described_class.csv_for_academic_year(academic_year) }

    it "produces a CSV file containing only the awards for the specified academic year" do
      expect(csv).to eq("school_urn,award_amount\n#{award.school_urn},#{award.award_amount}\n")
    end
  end

  describe ".last_updated_at" do
    let(:academic_year) { AcademicYear.current }
    before { create(:targeted_retention_incentive_payments_award, academic_year: academic_year - 1) }

    subject(:updated_at) { described_class.last_updated_at(academic_year) }

    context "when there are no records in the specified academic year" do
      it { is_expected.to be_nil }
    end

    context "when there are records in the specified academic year" do
      let!(:award) { create(:targeted_retention_incentive_payments_award, academic_year: academic_year) }
      it { is_expected.to eq(award.updated_at) }
    end
  end

  describe ".distinct_academic_years" do
    let(:academic_year) { AcademicYear.current }
    subject(:years) { described_class.distinct_academic_years }

    context "when there are no awards" do
      it { is_expected.to be_empty }
    end

    context "when there are awards" do
      before do
        create(:targeted_retention_incentive_payments_award, academic_year: academic_year)
        create(:targeted_retention_incentive_payments_award, academic_year: academic_year)
        create(:targeted_retention_incentive_payments_award, academic_year: academic_year - 1)
        create(:targeted_retention_incentive_payments_award, academic_year: academic_year - 1)
      end

      it { is_expected.to eq([academic_year.to_s, (academic_year - 1).to_s]) }
    end
  end
end
