require "rails_helper"

RSpec.describe Journeys::AdditionalPaymentsForTeaching::EligibilityConfirmedForm, type: :model do
  before { create(:journey_configuration, :additional_payments) }

  subject(:form) { described_class.new(claim:, journey:, journey_session:, params:) }

  let(:journey) { Journeys::AdditionalPaymentsForTeaching }
  let(:journey_session) { create(:additional_payments_session, answers: answers) }
  let(:ecp_claim) { create(:claim, :eligible, policy: Policies::EarlyCareerPayments) }
  let(:lupp_claim) { create(:claim, :eligible, policy: Policies::LevellingUpPremiumPayments) }
  let(:claim) { CurrentClaim.new(claims: [ecp_claim, lupp_claim]) }
  let(:slug) { "eligibility-confirmed" }
  let(:params) { ActionController::Parameters.new({slug:, claim: claim_params}) }
  let(:claim_params) { {selected_claim_policy: "EarlyCareerPayments"} }
  let(:answers) { {} }

  describe "validations" do
    let(:answers) { build(:additional_payments_answers, :ecp_and_lup_eligible) }

    it do
      is_expected.to validate_presence_of(:selected_claim_policy)
        .with_message("Select an additional payment")
    end

    it do
      is_expected.to validate_inclusion_of(:selected_claim_policy)
        .in_array(["EarlyCareerPayments", "LevellingUpPremiumPayments"])
        .with_message("Select a valid additional payment")
    end
  end

  describe "#save" do
    context "valid params - LUPP" do
      let(:claim_params) { {selected_claim_policy: "EarlyCareerPayments"} }
      let(:answers) { build(:additional_payments_answers, :ecp_eligible) }

      it { expect(form.save).to eq(true) }

      it do
        expect { form.save }.to change { journey_session.reload.answers.selected_policy }.to("EarlyCareerPayments")
      end
    end

    context "valid params - ECP" do
      let(:claim_params) { {selected_claim_policy: "LevellingUpPremiumPayments"} }
      let(:answers) { build(:additional_payments_answers, :lup_eligible) }

      it { expect(form.save).to eq(true) }

      it do
        expect { form.save }.to change { journey_session.reload.answers.selected_policy }.to("LevellingUpPremiumPayments")
      end
    end

    context "invalid params" do
      let(:claim_params) { {selected_claim_policy: "InvalidPolicy"} }
      let(:answers) { build(:additional_payments_answers, :lup_eligible) }

      it { expect(form.save).to eq(false) }
    end
  end

  describe "#single_choice_only?" do
    context "when eligible for one policy only" do
      let(:ecp_claim) { create(:claim, :ineligible, policy: Policies::EarlyCareerPayments) }
      let(:lupp_claim) { create(:claim, :eligible, policy: Policies::LevellingUpPremiumPayments) }
      let(:answers) do
        build(
          :additional_payments_answers,
          :ecp_ineligible,
          :lup_eligible
        )
      end

      it { expect(form.single_choice_only?).to eq(true) }
    end

    context "when eligible for more than one policy" do
      let(:ecp_claim) { create(:claim, :eligible, policy: Policies::EarlyCareerPayments) }
      let(:lupp_claim) { create(:claim, :eligible, policy: Policies::LevellingUpPremiumPayments) }
      let(:answers) do
        build(:additional_payments_answers, :ecp_and_lup_eligible)
      end

      it { expect(form.single_choice_only?).to eq(false) }
    end
  end

  describe "#selected_policy?" do
    subject { form.selected_policy?(policy_in_the_argument) }

    let(:answers) { build(:additional_payments_answers, :ecp_and_lup_eligible, with_selected_policy) }

    context "when the policy in the argument is ECP" do
      let(:policy_in_the_argument) { Policies::EarlyCareerPayments }

      context "selected policy is ECP" do
        let(:with_selected_policy) { :with_selected_policy_ecp }

        it { is_expected.to eq(true) }
      end

      context "selected policy is LUPP" do
        let(:with_selected_policy) { :with_selected_policy_lupp }

        it { is_expected.to eq(false) }
      end
    end

    context "when the policy in the argument is LUPP" do
      let(:policy_in_the_argument) { Policies::LevellingUpPremiumPayments }

      context "selected policy is ECP" do
        let(:with_selected_policy) { :with_selected_policy_ecp }

        it { is_expected.to eq(false) }
      end

      context "selected policy is LUPP" do
        let(:with_selected_policy) { :with_selected_policy_lupp }

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
      let(:sorted_policies) { [Policies::EarlyCareerPayments, Policies::LevellingUpPremiumPayments] }

      it { is_expected.to eq("earlycareerpayments") }
    end

    context "when the first eligible policy is LevellingUpPremiumPayments" do
      let(:sorted_policies) { [Policies::LevellingUpPremiumPayments, Policies::EarlyCareerPayments] }

      it { is_expected.to eq("levellinguppremiumpayments") }
    end
  end

  describe "#allowed_policy_names" do
    subject { form.allowed_policy_names }

    let(:answers) do
      build(:additional_payments_answers, :ecp_and_lup_eligible)
    end

    it { is_expected.to eq(["EarlyCareerPayments", "LevellingUpPremiumPayments"]) }
  end
end
