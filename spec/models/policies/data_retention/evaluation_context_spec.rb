require "rails_helper"

RSpec.describe Policies::DataRetention::EvaluationContext do
  let(:evaluation_context) { described_class.new(claim) }

  let(:current_academic_year) { AcademicYear.new(2025) }

  let(:previous_academic_year) { current_academic_year.previous }

  let(:in_current_academic_year) do
    current_academic_year.start_of_autumn_term + 1.second
  end

  let(:in_previous_academic_year) do
    previous_academic_year.start_of_autumn_term + 1.second
  end

  before do
    allow(AcademicYear).to receive(:current) { current_academic_year }
  end

  describe "#old_paid_claim?" do
    subject { evaluation_context.old_paid_claim? }

    let(:claim) { create(:claim) }

    context "when the claim is not paid" do
      it { is_expected.to be false }
    end

    context "when the claim is paid" do
      context "when the claim's scheduled payment date is in the current academic year" do
        before do
          create(
            :payment,
            claims: [claim],
            scheduled_payment_date: in_current_academic_year
          )
        end

        it { is_expected.to be false }
      end

      context "when the claim's scheduled payment date is in the previous academic year" do
        before do
          create(
            :payment,
            claims: [claim],
            scheduled_payment_date: in_previous_academic_year
          )
        end

        it { is_expected.to be true }
      end
    end
  end

  describe "#old_rejected_claim?" do
    subject { evaluation_context.old_rejected_claim? }

    let(:claim) { create(:claim, :submitted) }

    context "when the claim is undecided" do
      it { is_expected.to be false }
    end

    context "when the claim is approved" do
      before do
        create(
          :decision,
          :approved,
          claim: claim,
          created_at: in_previous_academic_year
        )
      end

      it { is_expected.to be false }
    end

    context "when the claim is rejected" do
      context "when the claim was rejected in the current academic year" do
        before do
          create(
            :decision,
            :rejected,
            claim: claim,
            created_at: in_current_academic_year
          )
        end

        it { is_expected.to be false }
      end

      context "when the claim was rejected in a previous academic year" do
        before do
          create(
            :decision,
            :rejected,
            claim: claim,
            created_at: in_previous_academic_year
          )
        end

        it { is_expected.to be true }
      end
    end
  end

  describe "#submitted_in_previous_academic_term?" do
    subject { evaluation_context.submitted_in_prior_academic_term? }

    context "when the claim was submitted in the current AY" do
      let(:claim) { create(:claim, academic_year: current_academic_year) }

      it { is_expected.to be false }
    end

    context "when the claim was submitted in a prior AY" do
      let(:claim) { create(:claim, academic_year: previous_academic_year) }

      it { is_expected.to be true }
    end
  end

  describe "#inactive_claim_submitted_in_prior_academic_term?" do
    subject { evaluation_context.inactive_claim_submitted_in_prior_academic_term? }

    context "when the claim was submitted in the current AY" do
      let(:claim) { create(:claim, academic_year: current_academic_year) }

      it { is_expected.to be false }
    end

    context "when the claim was submitted in a prior AY" do
      context "when the claim is active" do
        context "when the claim is undecided" do
          let(:claim) { create(:claim, academic_year: previous_academic_year) }

          it { is_expected.to be false }
        end

        context "when the claim is approved but unpaid" do
          let(:claim) do
            create(:claim, :submitted, academic_year: previous_academic_year)
          end

          before do
            create(
              :decision,
              :approved,
              claim: claim,
              created_at: in_previous_academic_year
            )
          end

          it { is_expected.to be false }
        end
      end

      context "when the claim is inactive" do
        let(:claim) { create(:claim, academic_year: previous_academic_year) }

        before do
          create(
            :decision,
            :rejected,
            claim: claim,
            created_at: in_previous_academic_year
          )
        end

        it { is_expected.to be true }
      end
    end
  end

  describe "#inactive_claim_over_five_years_old?" do
    subject { evaluation_context.inactive_claim_over_five_years_old? }

    let(:claim) { create(:claim, academic_year: academic_year) }

    context "when the claim is less than five academic years old" do
      let(:academic_year) { AcademicYear.current - 4 }

      before do
        create(
          :decision,
          :rejected,
          claim: claim,
          created_at: academic_year.start_of_autumn_term + 1.second
        )
      end

      it { is_expected.to be false }
    end

    context "when the claim is five or more academic years old" do
      let(:academic_year) { AcademicYear.current - 5 }

      context "when the claim is active" do
        it { is_expected.to be false }
      end

      context "when the claim is not active" do
        before do
          create(
            :decision,
            :rejected,
            claim: claim,
            created_at: academic_year.start_of_autumn_term - 1.second
          )
        end

        it { is_expected.to be true }
      end
    end
  end
end
