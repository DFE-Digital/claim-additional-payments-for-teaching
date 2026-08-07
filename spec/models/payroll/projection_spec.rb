require "rails_helper"

RSpec.describe Payroll::Projection do
  let!(:previous_payroll_run) { create(:payroll_run, created_at: 1.day.ago) }

  let!(:undecided_out_of_range) do
    create(
      :claim,
      policy: Policies::FurtherEducationPayments,
      decision_deadline: 2.months.from_now,
      eligibility_attributes: {
        award_amount: 2
      }
    )
  end

  let!(:undecided_in_range) do
    create(
      :claim,
      policy: Policies::FurtherEducationPayments,
      decision_deadline: 3.weeks.from_now,
      eligibility_attributes: {
        award_amount: 3
      }
    )
  end

  let!(:approved) do
    # decision date out of range but approved so in next payroll run
    create(
      :claim,
      :approved,
      policy: Policies::EarlyYearsTeachersFinancialIncentivePayments,
      decision_deadline: 2.months.from_now,
      eligibility_attributes: {
        award_amount: 5
      }
    )
  end

  let!(:rejected) do
    # rejected claim, not included
    create(
      :claim,
      :rejected,
      policy: Policies::EarlyYearsTeachersFinancialIncentivePayments,
      decision_deadline: 1.day.from_now,
      eligibility_attributes: {
        award_amount: 7
      }
    )
  end

  let!(:paid) do
    # paid claim, not included
    create(
      :claim,
      :approved,
      policy: Policies::StudentLoans,
      decision_deadline: 2.months.from_now,
      eligibility_attributes: {
        award_amount: 11
      }
    ).tap do |claim|
      create(:payment, claims: [claim], payroll_run: previous_payroll_run)
    end
  end

  let!(:topped_up) do
    # Paid claim, topped up, included
    create(
      :claim,
      :approved,
      policy: Policies::StudentLoans,
      decision_deadline: 6.months.ago,
      eligibility_attributes: {
        award_amount: 13
      }
    ).tap do |claim|
      create(:payment, claims: [claim], payroll_run: previous_payroll_run)

      create(:topup, claim: claim, award_amount: 17)
    end
  end

  let!(:paid_topup) do
    # Paid claim, topped up, included
    create(
      :claim,
      :approved,
      policy: Policies::TargetedRetentionIncentivePayments,
      decision_deadline: 6.months.ago,
      eligibility_attributes: {
        award_amount: 19
      }
    ).tap do |claim|
      create(:payment, claims: [claim], payroll_run: previous_payroll_run)

      create(
        :topup,
        claim: claim,
        award_amount: 23,
        payment: create(:payment, payroll_run: previous_payroll_run)
      )
    end
  end

  let!(:projection) { described_class.new }

  describe "#total_award_amount" do
    subject { projection.total_award_amount }

    it do
      is_expected.to eq(undecided_in_range.award_amount + approved.award_amount)
    end
  end

  describe "#number_of_claims_for_policy" do
    subject do
      projection.number_of_claims_for_policy(Policies::FurtherEducationPayments)
    end

    it { is_expected.to eq 1 }
  end

  describe "#total_claim_amount_for_policy" do
    subject do
      projection.total_claim_amount_for_policy(Policies::FurtherEducationPayments)
    end

    it { is_expected.to eq 3 }
  end

  describe "#number_of_topups_for_policy" do
    context "when no topups for policy" do
      subject do
        projection.number_of_topups_for_policy(Policies::TargetedRetentionIncentivePayments)
      end

      it { is_expected.to eq 0 }
    end

    context "when topup for policy" do
      subject do
        projection.number_of_topups_for_policy(Policies::StudentLoans)
      end

      it { is_expected.to eq 1 }
    end
  end

  describe "#total_topup_amount_for_policy" do
    context "when no topups for policy" do
      subject do
        projection.total_topup_amount_for_policy(Policies::FurtherEducationPayments)
      end

      it { is_expected.to eq 0 }
    end

    context "when topup for policy" do
      subject do
        projection.total_topup_amount_for_policy(Policies::StudentLoans)
      end

      it { is_expected.to eq 17 }
    end
  end

  describe "#claims_count" do
    subject { projection.claims_count }

    it { is_expected.to eq [undecided_in_range, approved].size }
  end

  describe "#topups_count" do
    subject { projection.topups_count }

    it { is_expected.to eq [topped_up].size }
  end
end
