require "rails_helper"

RSpec.describe(
  Journeys::EarlyYearsTeachersFinancialIncentivePayments::SessionAnswers
) do
  describe "#previous_claim" do
    before do
      create(
        :journey_configuration,
        :early_years_teachers_financial_incentive_payments,
        current_academic_year:
      )
    end

    let(:claim_2025_2026) do
      create(
        :claim,
        :submitted,
        policy: Policies::EarlyYearsTeachersFinancialIncentivePayments,
        academic_year: AcademicYear.new(2025),
        onelogin_uid: "abc123"
      )
    end

    let(:claim_2026_2027) do
      create(
        :claim,
        :submitted,
        policy: Policies::EarlyYearsTeachersFinancialIncentivePayments,
        academic_year: AcademicYear.new(2026),
        onelogin_uid: "abc123"
      )
    end

    let(:claim_2027_2028) do
      create(
        :claim,
        :submitted,
        policy: Policies::EarlyYearsTeachersFinancialIncentivePayments,
        academic_year: AcademicYear.new(2027),
        onelogin_uid: "abc123"
      )
    end

    subject do
      described_class.new(
        teacher_auth_one_login_uid: "abc123"
      )
    end

    context "when configured year is 2025/2026" do
      let(:current_academic_year) { AcademicYear.new(2025) }

      it "returns only claims in 2025/2026" do
        expect(subject.previous_claim).to be_nil
      end

      it "returns only claims in 2025/2026" do
        claim_2025_2026

        expect(subject.previous_claim).to eql(claim_2025_2026)
      end
    end

    context "when configured year is 2026/2027" do
      let(:current_academic_year) { AcademicYear.new(2026) }

      it "returns claims in [2025/2026, 2026/2027]" do
        expect(subject.previous_claim).to be_nil
      end

      it "returns claims in [2025/2026, 2026/2027]" do
        claim_2025_2026

        expect(subject.previous_claim).to eql(claim_2025_2026)
      end

      it "returns claims in [2025/2026, 2026/2027]" do
        claim_2026_2027

        expect(subject.previous_claim).to eql(claim_2026_2027)
      end
    end

    context "when configured year is 2027/2028" do
      let(:current_academic_year) { AcademicYear.new(2027) }

      it "returns only claims in 2027/2028" do
        claim_2025_2026
        claim_2026_2027

        expect(subject.previous_claim).to be_nil
      end

      it "returns only claims in 2027/2028" do
        claim_2027_2028

        expect(subject.previous_claim).to eql(claim_2027_2028)
      end
    end
  end
end
