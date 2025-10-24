require "rails_helper"

RSpec.describe Admin::ClaimsFilterForm, type: :model do
  describe "#claims" do
    let(:session) { {} }
    let(:filters) { {} }

    subject { described_class.new(filters:, session:) }

    context "when rejected whilst awaiting provider verification" do
      let!(:claim) do
        create(
          :claim,
          :rejected,
          :awaiting_provider_verification,
          policy: Policies::FurtherEducationPayments
        )
      end

      let(:filters) { {status: "awaiting_provider_verification"} }

      it "filtering by status awaiting provider verification excludes them" do
        expect(subject.claims).not_to include(claim)
      end
    end

    context "when the status is awaiting_provider_verification" do
      it "returns the expected claims" do
        claim_awaiting_provider_verification_1 = build(
          :claim,
          :submitted,
          :further_education
        )

        create(
          :further_education_payments_eligibility,
          claim: claim_awaiting_provider_verification_1,
          flagged_as_duplicate: false
        )

        claim_awaiting_provider_verification_2 = build(
          :claim,
          :submitted,
          :further_education
        )

        create(
          :further_education_payments_eligibility,
          claim: claim_awaiting_provider_verification_2,
          flagged_as_duplicate: true
        )

        create(
          :note,
          claim: claim_awaiting_provider_verification_2,
          label: "provider_verification"
        )

        create(
          :note,
          claim: claim_awaiting_provider_verification_2,
          label: "provider_verification"
        )

        _claim_not_awating_provider_verification = build(:claim, :submitted)

        create(
          :further_education_payments_eligibility,
          :provider_verification_completed
        )

        form = described_class.new(
          session: {},
          filters: {
            status: "awaiting_provider_verification"
          }
        )

        expect(form.claims).to match_array(
          [
            claim_awaiting_provider_verification_1,
            claim_awaiting_provider_verification_2
          ]
        )
      end
    end

    context "filtering for unassigned + auto approved claims" do
      subject { described_class.new(session:, filters: {team_member:, status:}) }

      let(:team_member) { "unassigned" }
      let(:status) { "automatically_approved" }
      let(:session) { {} }

      before do
        create(:claim, :submitted, :auto_approved, :current_academic_year)
      end

      it "works" do
        expect(subject.claims.count).to eql(1)
      end
    end

    context "filtering for quality_assured" do
      let!(:qa_approved_claim) { create(:claim, :approved, :qa_completed, :current_academic_year) }
      let!(:qa_rejected_claim) { create(:claim, :rejected, :qa_completed, :current_academic_year) }

      let(:filters) { {status: "quality_assured"} }

      it "returns all quality assured claims" do
        expect(subject.claims.size).to eql(2)
      end
    end

    context "filtering for quality_assured_approved" do
      let!(:qa_approved_claim) { create(:claim, :approved, :qa_completed, :current_academic_year) }
      let!(:qa_rejected_claim) { create(:claim, :rejected, :qa_completed, :current_academic_year) }

      let(:filters) { {status: "quality_assured_approved"} }

      it "returns all approved quality assured claims" do
        expect(subject.claims).to eq([qa_approved_claim])
      end
    end

    context "filtering for quality_assured_rejected" do
      let!(:qa_approved_claim) { create(:claim, :approved, :qa_completed, :current_academic_year) }
      let!(:qa_rejected_claim) { create(:claim, :rejected, :qa_completed, :current_academic_year) }

      let(:filters) { {status: "quality_assured_rejected"} }

      it "returns all rejected quality assured claims" do
        expect(subject.claims).to eq([qa_rejected_claim])
      end
    end

    context "filtering with EY awaiting filters" do
      let!(:claim_awaiting_claimant) { create(:claim, submitted_at: nil, policy: Policies::EarlyYearsPayments) }
      let!(:claim_within_retention_period) { create(:claim, :submitted, policy: Policies::EarlyYearsPayments) }
      let!(:claim_after_retention_period) { create(:claim, :submitted, policy: Policies::EarlyYearsPayments) }
      let!(:claim_rejected) { create(:claim, :rejected, submitted_at: nil, policy: Policies::EarlyYearsPayments) }

      before do
        claim_within_retention_period.eligibility.update(start_date: (Policies::EarlyYearsPayments::RETENTION_PERIOD - 1.month).ago)
        claim_after_retention_period.eligibility.update(start_date: (Policies::EarlyYearsPayments::RETENTION_PERIOD + 1.month).ago)
      end

      context "awaiting_claimant_data filter" do
        let(:filters) { {status: "awaiting_claimant_data"} }

        it "returns claims awaiting claimant data" do
          expect(subject.claims).to eq([claim_awaiting_claimant])
        end
      end

      context "awaiting_retention_period_completion filter" do
        let(:filters) { {status: "awaiting_retention_period_completion"} }

        it "returns claims awaiting retention period completion" do
          expect(subject.claims).to eq([claim_within_retention_period])
        end
      end

      context "awaiting_retention_check_data filter" do
        let(:filters) { {status: "awaiting_retention_check_data"} }

        it "awaiting_retention_check_data filter" do
          expect(subject.claims).to eq([claim_after_retention_period])
        end
      end
    end

    context "when approved awaiting QA" do
      let(:current_academic_year) { AcademicYear.current }

      let!(:claim) do
        create(
          :claim,
          :approved,
          qa_required: true,
          academic_year: current_academic_year,
          policy: Policies::EarlyYearsPayments
        )
      end

      let!(:claim_previous_ay) do
        create(
          :claim,
          :approved,
          qa_required: true,
          academic_year: current_academic_year.previous,
          policy: Policies::EarlyYearsPayments
        )
      end

      let(:filters) { {status: "approved_awaiting_qa"} }

      it "filtering by status approved_awaiting_qa includes them" do
        expect(subject.claims).to include(claim)
        expect(subject.claims).to include(claim_previous_ay)
      end
    end

    context "when rejected awaiting QA" do
      let(:current_academic_year) { AcademicYear.current }

      let!(:claim) do
        create(
          :claim,
          :rejected,
          qa_required: true,
          academic_year: current_academic_year,
          policy: Policies::EarlyYearsPayments
        )
      end

      let!(:claim_previous_ay) do
        create(
          :claim,
          :rejected,
          qa_required: true,
          academic_year: current_academic_year.previous,
          policy: Policies::EarlyYearsPayments
        )
      end

      let(:filters) { {status: "rejected_awaiting_qa"} }

      it "filtering by status rejected_awaiting_qa includes them" do
        expect(subject.claims).to include(claim)
        expect(subject.claims).to include(claim_previous_ay)
      end
    end

    context "when approved awaiting payroll" do
      let(:current_academic_year) { AcademicYear.current }

      let!(:claim) do
        create(
          :claim,
          :payrollable,
          academic_year: current_academic_year,
          policy: Policies::EarlyYearsPayments
        )
      end

      let!(:claim_previous_ay) do
        create(
          :claim,
          :payrollable,
          academic_year: current_academic_year.previous,
          policy: Policies::EarlyYearsPayments
        )
      end

      let(:filters) { {status: "approved_awaiting_payroll"} }

      it "filtering by status approved_awaiting_payroll includes them" do
        expect(subject.claims).to include(claim)
        expect(subject.claims).to include(claim_previous_ay)
      end
    end

    context "when automatically approved awaiting payroll" do
      let(:current_academic_year) { AcademicYear.current }

      let!(:claim) do
        create(
          :claim,
          :auto_approved,
          academic_year: current_academic_year,
          policy: Policies::FurtherEducationPayments
        )
      end

      let!(:claim_previous_ay) do
        create(
          :claim,
          :auto_approved,
          academic_year: current_academic_year.previous,
          policy: Policies::FurtherEducationPayments
        )
      end

      let(:filters) { {status: "automatically_approved_awaiting_payroll"} }

      it "filtering by status automatically_approved_awaiting_payroll includes them" do
        expect(subject.claims).to include(claim)
        expect(subject.claims).to include(claim_previous_ay)
      end
    end
  end
end
