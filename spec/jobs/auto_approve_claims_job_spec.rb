require "rails_helper"

RSpec.describe AutoApproveClaimsJob do
  subject(:auto_approve_claims_job) { described_class.new }

  it { is_expected.to be_a(CronJob) }

  describe ".cron_expression" do
    it { expect(described_class.cron_expression).to eq("0 8 * * 1-5") }
  end

  describe "#perform" do
    subject(:run_job) { auto_approve_claims_job.perform }

    let(:current_academic_year) { AcademicYear.current }
    let(:previous_academic_year) { current_academic_year - 1 }

    let(:claims_awaiting_decision_current_ay) do
      (
        create_list(:claim, 2, :submitted, academic_year: current_academic_year, policy: Policies::StudentLoans) +
        create_list(:claim, 2, :submitted, academic_year: current_academic_year, policy: Policies::EarlyCareerPayments) +
        create_list(:claim, 2, :submitted, academic_year: current_academic_year, policy: Policies::LevellingUpPremiumPayments)
      )
    end
    let(:claims_awaiting_decision_previous_ay) { create_list(:claim, 2, :submitted, academic_year: previous_academic_year, policy: Policies::StudentLoans) }
    let(:claims_awaiting_qa_current_ay) { create_list(:claim, 2, :submitted, :flagged_for_qa, academic_year: previous_academic_year, policy: Policies::StudentLoans) }
    let(:claims_rejected_current_ay) { create_list(:claim, 2, :rejected, academic_year: current_academic_year, policy: Policies::StudentLoans) }
    let(:claims_held_current_ay) { create_list(:claim, 2, :submitted, held: true, academic_year: current_academic_year, policy: Policies::StudentLoans) }

    shared_examples "excluding claims from auto-approval" do
      it "does not enqueue the job for auto-approval", :aggregate_failures do
        expected_excluded_claims.each do |claim|
          expect(AutoApproveClaimJob).not_to receive(:perform_later).with(claim)
        end

        run_job
      end
    end

    context "with claims awaiting decision from the current academic year" do
      let(:expected_approvable_claims) { claims_awaiting_decision_current_ay }

      before do
        allow_any_instance_of(ClaimAutoApproval).to receive(:eligible?).and_return(eligible?)
      end

      context "when the claims are eligible for auto-approval" do
        let(:eligible?) { true }

        it "enqueues another job to auto-approve them" do
          expected_approvable_claims.each do |claim|
            expect(AutoApproveClaimJob).to receive(:perform_later).with(claim)
          end

          run_job
        end
      end

      context "when the claims are not eligible for auto-approval" do
        let(:eligible?) { false }

        it "does not enqueue another job to auto-approve them" do
          expected_approvable_claims.each do |claim|
            expect(AutoApproveClaimJob).not_to receive(:perform_later).with(claim)
          end

          run_job
        end
      end
    end

    context "with claims awaiting decision from the previous academic year" do
      let(:expected_excluded_claims) { claims_awaiting_decision_previous_ay }
      it_behaves_like "excluding claims from auto-approval"
    end

    context "with claims awaiting QA" do
      let(:expected_excluded_claims) { claims_awaiting_qa_current_ay }
      it_behaves_like "excluding claims from auto-approval"
    end

    context "with rejected claims" do
      let(:expected_excluded_claims) { claims_rejected_current_ay }
      it_behaves_like "excluding claims from auto-approval"
    end

    context "with held claims" do
      let(:expected_excluded_claims) { claims_held_current_ay }
      it_behaves_like "excluding claims from auto-approval"
    end
  end
end
