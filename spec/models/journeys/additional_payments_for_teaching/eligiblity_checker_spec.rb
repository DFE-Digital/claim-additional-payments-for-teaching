require "rails_helper"

RSpec.describe Journeys::AdditionalPaymentsForTeaching::EligibilityChecker, type: :model do
  let!(:journey_configuration_ecp_lupp) { create(:journey_configuration, :additional_payments) }

  describe "#status" do
    subject { described_class.new(journey_session:).status }

    let(:journey_session) { build(:additional_payments_session) }

    let(:ecp_policy_eligibility_checker) { double }
    let(:lupp_policy_eligibility_checker) { double }

    before do
      allow(Policies::EarlyCareerPayments::PolicyEligibilityChecker)
        .to receive(:new)
        .with(answers: journey_session.answers)
        .and_return(ecp_policy_eligibility_checker)

      allow(Policies::LevellingUpPremiumPayments::PolicyEligibilityChecker)
        .to receive(:new)
        .with(answers: journey_session.answers)
        .and_return(lupp_policy_eligibility_checker)

      allow(ecp_policy_eligibility_checker).to receive(:status).and_return(ecp_status)
      allow(lupp_policy_eligibility_checker).to receive(:status).and_return(lupp_status)
    end

    context "any are :eligible_now (have :eligible_later and :eligible_now)" do
      let(:ecp_status) { :eligible_later }
      let(:lupp_status) { :eligible_now }

      it { is_expected.to eq(:eligible_now) }
    end

    context "none are :eligible_now but any are :eligible_later" do
      let(:ecp_status) { :ineligible }
      let(:lupp_status) { :eligible_later }

      it { is_expected.to eq(:eligible_later) }
    end

    context "all are :ineligible" do
      let(:ecp_status) { :ineligible }
      let(:lupp_status) { :ineligible }

      it { is_expected.to eq(:ineligible) }
    end

    context "one ineligible and one undetermined" do
      let(:ecp_status) { :ineligible }
      let(:lupp_status) { :undetermined }

      it { is_expected.to eq(:undetermined) }
    end

    context "all are :undetermined" do
      let(:ecp_status) { :undetermined }
      let(:lupp_status) { :undetermined }

      it { is_expected.to eq(:undetermined) }
    end
  end
end
