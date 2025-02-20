require "rails_helper"

RSpec.describe Journeys::AdditionalPaymentsForTeaching::EligibilityConfirmedForm, type: :model do
  before { create(:journey_configuration, :additional_payments, current_academic_year: AcademicYear.new(2023)) }

  subject(:form) { described_class.new(journey:, journey_session:, params:) }

  let(:journey) { Journeys::AdditionalPaymentsForTeaching }
  let(:journey_session) { create(:additional_payments_session, answers: answers) }
  let(:slug) { "eligibility-confirmed" }
  let(:params) { ActionController::Parameters.new({slug:, claim: claim_params}) }
  let(:claim_params) { {selected_claim_policy: "EarlyCareerPayments"} }
  let(:answers) { {} }

  describe "validations" do
    let(:answers) { build(:additional_payments_answers, :ecp_and_targeted_retention_incentive_eligible) }

    it do
      is_expected.to validate_presence_of(:selected_claim_policy)
        .with_message("Select an additional payment")
    end

    it do
      is_expected.to validate_inclusion_of(:selected_claim_policy)
        .in_array(["EarlyCareerPayments", "TargetedRetentionIncentivePayments"])
        .with_message("Select a valid additional payment")
    end
  end

  describe "#save" do
    context "valid params - Targeted Retention Incentive" do
      let(:claim_params) { {selected_claim_policy: "EarlyCareerPayments"} }
      let(:answers) { build(:additional_payments_answers, :ecp_eligible) }

      it { expect(form.save).to eq(true) }

      it do
        expect { form.save }.to change { journey_session.reload.answers.selected_policy }.to("EarlyCareerPayments")
      end
    end

    context "valid params - ECP" do
      let(:claim_params) { {selected_claim_policy: "TargetedRetentionIncentivePayments"} }
      let(:answers) { build(:additional_payments_answers, :targeted_retention_incentive_eligible) }

      it { expect(form.save).to eq(true) }

      it do
        expect { form.save }.to change { journey_session.reload.answers.selected_policy }.to("TargetedRetentionIncentivePayments")
      end
    end

    context "invalid params" do
      let(:claim_params) { {selected_claim_policy: "InvalidPolicy"} }
      let(:answers) { build(:additional_payments_answers, :targeted_retention_incentive_eligible) }

      it { expect(form.save).to eq(false) }
    end
  end

  describe "#single_choice_only?" do
    context "when eligible for one policy only" do
      let(:answers) do
        build(
          :additional_payments_answers,
          :ecp_ineligible,
          :targeted_retention_incentive_eligible
        )
      end

      it { expect(form.single_choice_only?).to eq(true) }
    end

    context "when eligible for more than one policy" do
      let(:answers) do
        build(:additional_payments_answers, :ecp_and_targeted_retention_incentive_eligible)
      end

      it { expect(form.single_choice_only?).to eq(false) }
    end
  end

  describe "#selected_policy?" do
    subject { form.selected_policy?(policy_in_the_argument) }

    let(:answers) { build(:additional_payments_answers, :ecp_and_targeted_retention_incentive_eligible, with_selected_policy) }

    context "when the policy in the argument is ECP" do
      let(:policy_in_the_argument) { Policies::EarlyCareerPayments }

      context "selected policy is ECP" do
        let(:with_selected_policy) { :with_selected_policy_ecp }

        it { is_expected.to eq(true) }
      end

      context "selected policy is Targeted Retention Incentive" do
        let(:with_selected_policy) { :with_selected_policy_targeted_retention_incentive }

        it { is_expected.to eq(false) }
      end
    end

    context "when the policy in the argument is Targeted Retention Incentive" do
      let(:policy_in_the_argument) { Policies::TargetedRetentionIncentivePayments }

      context "selected policy is ECP" do
        let(:with_selected_policy) { :with_selected_policy_ecp }

        it { is_expected.to eq(false) }
      end

      context "selected policy is Targeted Retention Incentive" do
        let(:with_selected_policy) { :with_selected_policy_targeted_retention_incentive }

        it { is_expected.to eq(true) }
      end
    end
  end

  describe "#first_eligible_compact_policy_name" do
    subject { form.first_eligible_compact_policy_name }

    before do
      allow(form).to receive(:policies_eligible_now_and_sorted).and_return(sorted_policies)
    end

    context "when the first eligible policy is EarlyCareerPayments" do
      let(:sorted_policies) { [Policies::EarlyCareerPayments, Policies::TargetedRetentionIncentivePayments] }

      it { is_expected.to eq("earlycareerpayments") }
    end

    context "when the first eligible policy is TargetedRetentionIncentivePayments" do
      let(:sorted_policies) { [Policies::TargetedRetentionIncentivePayments, Policies::EarlyCareerPayments] }

      it { is_expected.to eq("targetedretentionincentivepayments") }
    end
  end

  describe "#allowed_policy_names" do
    subject { form.allowed_policy_names }

    let(:answers) do
      build(:additional_payments_answers, :ecp_and_targeted_retention_incentive_eligible)
    end

    it { is_expected.to eq(["EarlyCareerPayments", "TargetedRetentionIncentivePayments"]) }
  end
end
