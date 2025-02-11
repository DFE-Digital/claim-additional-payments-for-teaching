require "rails_helper"

RSpec.describe Topup, type: :model do
  let(:user) { create(:dfe_signin_user) }
  let!(:journey_configuration) { create(:journey_configuration, :additional_payments) }
  let(:lup_claim) { create(:claim, :approved, policy: Policies::LevellingUpPremiumPayments, eligibility: lup_eligibility) }
  let(:lup_eligibility) { build(:levelling_up_premium_payments_eligibility, :eligible, award_amount: 2000.0) }
  let!(:payment) { create(:payment, claims: [lup_claim]) }

  before do
    award = lup_claim.eligibility.current_school.levelling_up_premium_payments_awards.by_academic_year(lup_claim.academic_year).first
    award.update!(award_amount: award.award_amount + BigDecimal("1000.00"))
  end

  context "topup to large" do
    it "topup fails validation" do
      topup = lup_claim.topups.create(award_amount: "1001.00", created_by: user)
      expect(topup).to_not be_persisted
      expect(topup.errors.first.message).to eq("Enter a positive amount up to £1,000.00 (inclusive)")
    end
  end

  context "topup at the limit" do
    it "creates the topup" do
      expect(lup_claim.topups.create(award_amount: "1000.00", created_by: user)).to be_persisted
    end
  end

  context "top less than the limit" do
    it "creates the topup" do
      expect(lup_claim.topups.create(award_amount: "500.00", created_by: user)).to be_persisted
    end
  end
end
