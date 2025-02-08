require "rails_helper"

RSpec.describe Policies::EarlyCareerPayments::PolicyEligibilityChecker, type: :model do
  let(:policy_eligibility_checker) { described_class.new(answers: answers) }

  describe "#trainee_teacher?" do
    subject { policy_eligibility_checker.trainee_teacher? }

    context "nqt_in_academic_year_after_itt is nil" do
      let(:answers) { build(:additional_payments_answers, nqt_in_academic_year_after_itt: nil) }

      it { is_expected.to be false }
    end

    context "nqt_in_academic_year_after_itt is true" do
      let(:answers) { build(:additional_payments_answers, nqt_in_academic_year_after_itt: true) }

      it { is_expected.to be false }
    end

    context "nqt_in_academic_year_after_itt is false (is a trainee teacher)" do
      let(:answers) { build(:additional_payments_answers, :trainee_teacher) }

      it { is_expected.to be true }
    end
  end

  describe "#induction_not_completed?" do
    subject { policy_eligibility_checker.induction_not_completed? }

    context "induction_completed is nil" do
      let(:answers) { build(:additional_payments_answers, induction_completed: nil) }

      it { is_expected.to be false }
    end

    context "induction_completed is true" do
      let(:answers) { build(:additional_payments_answers, induction_completed: true) }

      it { is_expected.to be false }
    end

    context "induction_completed is false" do
      let(:answers) { build(:additional_payments_answers, induction_completed: false) }

      it { is_expected.to be true }
    end
  end

  describe "#ecp_only_school?" do
    before { create(:journey_configuration, :additional_payments) }

    subject { policy_eligibility_checker.ecp_only_school? }

    context "when the current school is eligible for ECP only" do
      let(:answers) { build(:additional_payments_answers, :ecp_eligible) }

      it { is_expected.to eq(true) }
    end

    context "when the current school is eligible for ECP and Targeted Retention Incentive" do
      let(:answers) { build(:additional_payments_answers, :eligible_school_ecp_and_targeted_retention_incentive) }

      it { is_expected.to eq(false) }
    end

    context "when the current school is eligible for Targeted Retention Incentive only" do
      let(:answers) { build(:additional_payments_answers, :targeted_retention_incentive_eligible) }

      it { is_expected.to eq(false) }
    end
  end

  describe "#status" do
    let(:claim_year) { AcademicYear.new(2022) }

    before { create(:journey_configuration, :additional_payments, current_academic_year: claim_year) }

    subject { policy_eligibility_checker.status }

    it_behaves_like "eligibility_status", :early_career_payments

    context "ecp eligible" do
      let(:answers) { build(:additional_payments_answers, :ecp_eligible) }

      it { is_expected.to eq(:eligible_now) }
    end

    # By the 2022 policy year it's too late for this to apply to Targeted Retention Incentive so is ECP-specific now but
    # technically this check is generally needed for all policies
    context "no eligible subjects" do
      let(:answers) { build(:additional_payments_answers, :ecp_eligible, :with_no_eligible_subjects) }

      it { is_expected.to eq(:ineligible) }
    end

    context "ineligible ITT subject" do
      let(:answers) { build(:additional_payments_answers, :ecp_eligible, :ecp_ineligible_itt_subject) }

      it { is_expected.to eq(:ineligible) }
    end

    context "'None of the above' ITT subject" do
      let(:answers) { build(:additional_payments_answers, :ecp_eligible, eligible_itt_subject: :none_of_the_above) }

      it { is_expected.to eq(:ineligible) }
    end

    context "trainee teacher" do
      let(:answers) { build(:additional_payments_answers, :ecp_eligible, :trainee_teacher) }

      it { is_expected.to eq(:ineligible) }
    end

    context "induction not completed" do
      let(:answers) { build(:additional_payments_answers, :ecp_eligible, :eligible_school_ecp_only, induction_completed: false) }

      context "when the claim year is not the same as the end policy year" do
        let(:claim_year) { Policies::EarlyCareerPayments::POLICY_END_YEAR - 1 }

        it { is_expected.to eq(:eligible_later) }
      end

      context "when the claim year is the same as the end policy year" do
        let(:claim_year) { Policies::EarlyCareerPayments::POLICY_END_YEAR }

        it { is_expected.to eq(:ineligible) }
      end
    end
  end
end
