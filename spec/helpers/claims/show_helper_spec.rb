require "rails_helper"

RSpec.describe Claims::ShowHelper do
  let(:claim) { build(:claim, policy: policy) }

  describe "#fieldset_legend_css_class_for_journey" do
    subject(:css_class) { helper.fieldset_legend_css_class_for_journey(journey) }

    context "for Journeys::AdditionalPaymentsForTeaching" do
      let(:journey) { Journeys::AdditionalPaymentsForTeaching }

      it { is_expected.to eq("govuk-fieldset__legend--l") }
    end

    context "for Journeys::TeacherStudentLoanRepayment" do
      let(:journey) { Journeys::TeacherStudentLoanReimbursement }

      it { is_expected.to eq("govuk-fieldset__legend--xl") }
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
      let(:policy) { Policies::LevellingUpPremiumPayments }

      it { is_expected.to eq "levelling up premium payment" }
    end
  end

  describe "#award_amount" do
    let(:claim) { build(:claim, policy: Policies::LevellingUpPremiumPayments, eligibility: eligibility) }
    let(:eligibility) { build(:levelling_up_premium_payments_eligibility, :eligible, award_amount: award_amount) }
    let(:award_amount) { 2000.0 }

    before { create(:journey_configuration, :additional_payments) }

    it "returns a string currency representation" do
      expect(helper.award_amount(claim)).to eq("£2,000")
    end
  end
end
