require "rails_helper"

RSpec.describe Topup, type: :model do
  let(:user) { create(:dfe_signin_user) }
  let!(:journey_configuration) { create(:journey_configuration, :additional_payments) }
  let(:targeted_retention_incentive_claim) { create(:claim, :approved, policy: Policies::TargetedRetentionIncentivePayments, eligibility: targeted_retention_incentive_eligibility) }
  let(:targeted_retention_incentive_eligibility) { build(:targeted_retention_incentive_payments_eligibility, :eligible, award_amount: 2000.0) }
  let!(:payment) { create(:payment, claims: [targeted_retention_incentive_claim]) }

  before do
    award = targeted_retention_incentive_claim.eligibility.current_school.targeted_retention_incentive_payments_awards.by_academic_year(targeted_retention_incentive_claim.academic_year).first
    award.update!(award_amount: award.award_amount + BigDecimal("1000.00"))
  end

  context "topup to large" do
    it "topup fails validation" do
      topup = targeted_retention_incentive_claim.topups.create(award_amount: "1001.00", created_by: user)
      expect(topup).to_not be_persisted
      expect(topup.errors.first.message).to eq("Enter a positive amount up to £1,000.00 (inclusive)")
    end
  end

  context "topup at the limit" do
    it "creates the topup" do
      expect(targeted_retention_incentive_claim.topups.create(award_amount: "1000.00", created_by: user)).to be_persisted
    end
  end

  context "top less than the limit" do
    it "creates the topup" do
      expect(targeted_retention_incentive_claim.topups.create(award_amount: "500.00", created_by: user)).to be_persisted
    end
  end
end
