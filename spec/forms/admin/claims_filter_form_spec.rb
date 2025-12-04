require "rails_helper"

RSpec.describe Admin::ClaimsFilterForm, type: :model do
  describe "#claims" do
    let(:session) { {} }
    let(:filters) { {team_member: "all", policy: "all", status: "awaiting_decision"} }

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

      let(:filters) { {team_member: "all", policy: "all", status: "awaiting_provider_verification"} }

      it "filtering by status awaiting provider verification excludes them" do
        expect(subject.claims).not_to include(claim)
      end
    end

    context "when the status is awaiting_provider_verification" do
      context "when FE year 1" do
        let(:academic_year) { AcademicYear.new(2024) }

        it "returns the expected claims" do
          # Claim 1 - expected
          claim_awaiting_provider_verification_1 = build(
            :claim,
            :submitted,
            :further_education,
            academic_year:
          )

          create(
            :further_education_payments_eligibility,
            claim: claim_awaiting_provider_verification_1,
            flagged_as_duplicate: false
          )

          # Claim 2 - expected - provider form manually sent, so has a note
          claim_awaiting_provider_verification_2 = build(
            :claim,
            :submitted,
            :further_education,
            academic_year:
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

          # Claim 3 - not expected - already verified
          claim_not_awaiting_provider_verification = build(
            :claim,
            :submitted,
            :further_education,
            academic_year:
          )

          create(
            :further_education_payments_eligibility,
            :year_one_verified,
            claim: claim_not_awaiting_provider_verification,
            flagged_as_duplicate: false
          )

          form = described_class.new(
            session: {},
            filters: {
              team_member: "all",
              policy: "all",
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

      context "when FE year 2 or onwards" do
        let(:academic_year) { AcademicYear.current }

        it "returns the expected claims" do
          # Claim 1 - expected
          claim_awaiting_provider_verification_1 = build(
            :claim,
            :submitted,
            :further_education,
            academic_year:
          )

          create(
            :further_education_payments_eligibility,
            claim: claim_awaiting_provider_verification_1,
            flagged_as_duplicate: false,
            repeat_applicant_check_passed: true
          )

          # Claim 2 - not expected, a duplicate
          claim_awaiting_provider_verification_2 = build(
            :claim,
            :submitted,
            :further_education,
            academic_year:
          )

          create(
            :further_education_payments_eligibility,
            claim: claim_awaiting_provider_verification_2,
            flagged_as_duplicate: true,
            repeat_applicant_check_passed: true
          )

          # Claim 3 - not expected - repeat_applicant_check_passed failed
          claim_awaiting_provider_verification_3 = build(
            :claim,
            :submitted,
            :further_education,
            academic_year:
          )

          create(
            :further_education_payments_eligibility,
            claim: claim_awaiting_provider_verification_3,
            flagged_as_duplicate: false,
            repeat_applicant_check_passed: false
          )

          # Claim 4 - not expected - verified
          claim_awaiting_provider_verification_3 = build(
            :claim,
            :submitted,
            :further_education,
            academic_year:
          )

          create(
            :further_education_payments_eligibility,
            :provider_verification_completed,
            claim: claim_awaiting_provider_verification_3,
            flagged_as_duplicate: false,
            repeat_applicant_check_passed: true
          )

          form = described_class.new(
            session: {},
            filters: {
              team_member: "all",
              policy: "all",
              status: "awaiting_provider_verification"
            }
          )

          expect(form.claims).to match_array(
            [
              claim_awaiting_provider_verification_1
            ]
          )
        end
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

      let(:filters) { {team_member: "all", policy: "all", status: "quality_assured"} }

      it "returns all quality assured claims" do
        expect(subject.claims.size).to eql(2)
      end
    end

    context "filtering for quality_assured_approved" do
      let!(:qa_approved_claim) { create(:claim, :approved, :qa_completed, :current_academic_year) }
      let!(:qa_rejected_claim) { create(:claim, :rejected, :qa_completed, :current_academic_year) }

      let(:filters) { {team_member: "all", policy: "all", status: "quality_assured_approved"} }

      it "returns all approved quality assured claims" do
        expect(subject.claims).to eq([qa_approved_claim])
      end
    end

    context "filtering for quality_assured_rejected" do
      let!(:qa_approved_claim) { create(:claim, :approved, :qa_completed, :current_academic_year) }
      let!(:qa_rejected_claim) { create(:claim, :rejected, :qa_completed, :current_academic_year) }

      let(:filters) { {team_member: "all", policy: "all", status: "quality_assured_rejected"} }

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
        let(:filters) { {team_member: "all", policy: "all", status: "awaiting_claimant_data"} }

        it "returns claims awaiting claimant data" do
          expect(subject.claims).to eq([claim_awaiting_claimant])
        end
      end

      context "awaiting_retention_period_completion filter" do
        let(:filters) { {team_member: "all", policy: "all", status: "awaiting_retention_period_completion"} }

        it "returns claims awaiting retention period completion" do
          expect(subject.claims).to eq([claim_within_retention_period])
        end
      end

      context "awaiting_retention_check_data filter" do
        let(:filters) { {team_member: "all", policy: "all", status: "awaiting_retention_check_data"} }

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

      let(:filters) { {team_member: "all", policy: "all", status: "approved_awaiting_qa"} }

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

      let(:filters) { {team_member: "all", policy: "all", status: "rejected_awaiting_qa"} }

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

      let(:filters) { {team_member: "all", policy: "all", status: "approved_awaiting_payroll"} }

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

      let(:filters) { {team_member: "all", policy: "all", status: "automatically_approved_awaiting_payroll"} }

      it "filtering by status automatically_approved_awaiting_payroll includes them" do
        expect(subject.claims).to include(claim)
        expect(subject.claims).to include(claim_previous_ay)
      end
    end
  end

  describe "#save_to_session!" do
    let(:session) { {} }
    let(:filters) { {team_member: "user-123", policy: "further-education-payments", status: "approved"} }
    subject { described_class.new(filters:, session:) }

    it "saves filters to session with symbol keys" do
      subject.save_to_session!

      expect(session[:filter]).to eq({
        "team_member" => "user-123",
        "policy" => "further-education-payments",
        "status" => "approved"
      })
    end

    it "saves page to session" do
      subject.save_to_session!

      expect(session[:page]).to eq(1)
    end

    context "when page is set" do
      let(:filters) { {team_member: "all", policy: "all", status: "awaiting_decision"} }
      subject { described_class.new(filters:, session:, selected_page: 3) }

      it "saves the current page" do
        subject.save_to_session!

        expect(session[:page]).to eq(3)
      end
    end
  end

  describe "#reset?" do
    let(:session) { {} }
    subject { described_class.new(filters:, session:) }

    context "when reset filter is present" do
      let(:filters) { {reset: true} }

      it "returns true" do
        expect(subject.reset?).to be true
      end
    end

    context "when reset filter is not present" do
      let(:filters) { {} }

      it "returns false" do
        expect(subject.reset?).to be false
      end
    end
  end

  describe "filter accessors with session fallback" do
    let(:session) do
      {
        filter: {
          "team_member" => "session-user",
          "policy" => "early-years",
          "status" => "rejected"
        }
      }
    end
    subject { described_class.new(filters:, session:) }

    context "when filters are provided" do
      let(:filters) { {team_member: "param-user", policy: "further-education-payments"} }

      it "returns the filter values from params" do
        expect(subject.team_member).to eq("param-user")
        expect(subject.policy).to eq("further-education-payments")
      end

      it "falls back to session for filters not in params" do
        expect(subject.status).to eq("rejected")
      end
    end

    context "when filters are not provided" do
      let(:filters) { {} }

      it "returns values from session" do
        expect(subject.team_member).to eq("session-user")
        expect(subject.policy).to eq("early-years")
        expect(subject.status).to eq("rejected")
      end
    end

    context "when reset is applied" do
      let(:filters) { {reset: true} }

      it "returns defaults" do
        expect(subject.team_member).to eq("all")
        expect(subject.policy).to eq("all")
        expect(subject.status).to eq("awaiting_decision")
      end
    end
  end

  describe "#page with session and filter change detection" do
    let(:session) { {} }
    let(:filters) { {} }
    let(:selected_page) { nil }
    subject { described_class.new(filters:, session:, selected_page:) }

    context "when selected_page is provided" do
      let(:selected_page) { 5 }

      it "returns the selected page" do
        expect(subject.page).to eq(5)
      end
    end

    context "when page is in session" do
      let(:session) { {page: 3} }

      it "returns the page from session" do
        expect(subject.page).to eq(3)
      end
    end

    context "when reset is applied" do
      let(:filters) { {reset: true} }
      let(:session) { {page: 5} }

      it "returns 1" do
        expect(subject.page).to eq(1)
      end
    end

    context "when filters change from session" do
      let(:session) do
        {
          filter: {
            "team_member" => "user-123",
            "policy" => "further-education-payments",
            "status" => "awaiting_decision"
          },
          page: 5
        }
      end
      let(:filters) { {team_member: "user-456", policy: "further-education-payments", status: "awaiting_decision"} }

      it "returns 1 to reset to first page" do
        expect(subject.page).to eq(1)
      end
    end

    context "when filters do not change from session" do
      let(:session) do
        {
          filter: {
            "team_member" => "user-123",
            "policy" => "further-education-payments",
            "status" => "all"
          },
          page: 3
        }
      end
      let(:filters) do
        {
          team_member: "user-123",
          policy: "further-education-payments",
          status: "all"
        }
      end

      it "preserves the page from session" do
        expect(subject.page).to eq(3)
      end
    end

    context "when no page or session data is provided" do
      it "defaults to 1" do
        expect(subject.page).to eq(1)
      end
    end
  end
end
