require "rails_helper"

RSpec.describe Claims::ShowHelper do
  let(:claim) { build(:claim, policy: policy) }

  describe "#claim_submitted_title(claim)" do
    context "with a StudentLoans policy" do
      let(:policy) { Policies::StudentLoans }

      it "returns the correct content block" do
        expect(helper.claim_submitted_title(claim)).to include("Claim submitted")
      end
    end

    context "with a EarlyCareerPayments policy" do
      let(:policy) { Policies::EarlyCareerPayments }

      it "returns the correct content block" do
        expect(helper.claim_submitted_title(claim)).to include("You applied for an early-career payment")
      end
    end

    context "with a LevellingUpPremiumPayments policy" do
      let(:policy) { LevellingUpPremiumPayments }

      it "returns the correct content block" do
        expect(helper.claim_submitted_title(claim)).to include("You applied for a levelling up premium payment")
      end
    end
  end

  describe "#shared_view_css_class_size(claim)" do
    context "with a StudentLoans policy" do
      let(:policy) { Policies::StudentLoans }

      it "returns the correct css sizing" do
        expect(helper.shared_view_css_class_size(claim)).to eq "xl"
      end
    end

    context "with a EarlyCareerPayments policy" do
      let(:policy) { Policies::EarlyCareerPayments }

      it "returns the correct css sizing" do
        expect(helper.shared_view_css_class_size(claim)).to eq "l"
      end
    end
  end

  describe "#policy_name" do
    subject(:name) { helper.policy_name(claim) }

    context "with a StudentLoans policy" do
      let(:policy) { Policies::StudentLoans }

      it { is_expected.to eq "student loan" }
    end

    context "with a EarlyCareerPayments policy" do
      let(:policy) { Policies::EarlyCareerPayments }

      it { is_expected.to eq "early-career payment" }
    end

    context "with a LevellingUpPremiumPayments policy" do
      let(:policy) { LevellingUpPremiumPayments }

      it { is_expected.to eq "levelling up premium payment" }
    end
  end

  describe "#award_amount" do
    let(:claim) { build(:claim, policy: LevellingUpPremiumPayments, eligibility: eligibility) }
    let(:eligibility) { build(:levelling_up_premium_payments_eligibility, :eligible, award_amount: award_amount) }
    let(:award_amount) { 2000.0 }

    before { create(:journey_configuration, :additional_payments) }

    it "returns a string currency representation" do
      expect(helper.award_amount(claim)).to eq("£2,000")
    end
  end
end
