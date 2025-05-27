require "rails_helper"

RSpec.describe Claims::ShowHelper do
  describe "#policy_name" do
    subject(:name) { helper.policy_name(policy) }

    context "with a StudentLoans policy" do
      let(:policy) { Policies::StudentLoans }

      it { is_expected.to eq "student loan" }
    end

    context "with a EarlyCareerPayments policy" do
      let(:policy) { Policies::EarlyCareerPayments }

      it { is_expected.to eq "early-career payment" }
    end

    context "with a TargetedRetentionIncentivePayments policy" do
      let(:policy) { Policies::TargetedRetentionIncentivePayments }

      it { is_expected.to eq "school targeted retention incentive" }
    end
  end

  describe "#award_amount" do
    let(:award_amount) { 2000.0 }

    before { create(:journey_configuration, :additional_payments) }

    it "returns a string currency representation" do
      expect(helper.award_amount(award_amount)).to eq("£2,000")
    end
  end
end
