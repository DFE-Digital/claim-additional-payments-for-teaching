require "rails_helper"

RSpec.describe DeletePiiFromOldClaimsJob do
  describe "#perform" do
    let(:over_two_months_ago) { 2.months.ago - 1.day }

    it "deletes the PII from eligible claims" do
      submitted_claim = create(:claim, :submitted)
      rejected_claim = create(:claim, :submitted)
      create(:decision, :rejected, claim: rejected_claim, created_at: over_two_months_ago)
      paid_claim = create(:claim, :approved)
      create(:payment, :with_figures, claims: [paid_claim], scheduled_payment_date: over_two_months_ago)

      DeletePiiFromOldClaimsJob.new.perform

      expect(Claim.find(submitted_claim.id).personal_data_removed_at).to be_nil
      expect(Claim.find(rejected_claim.id).personal_data_removed_at).to_not be_nil
      expect(Claim.find(paid_claim.id).personal_data_removed_at).to_not be_nil
    end
  end
end
