require "rails_helper"

RSpec.describe PurgeUnsubmittedClaimsJob do
  describe "#perform" do
    let(:over_24_hours_ago) { 24.hours.ago - 1.second }
    let(:four_hours_ago) { 4.hours.ago }

    it "destroys any unsubmitted claims that have not been updated in the last 24 hours" do
      expired_unsubmitted_claim = create(:claim, updated_at: over_24_hours_ago)
      active_unsubmitted_claim = create(:claim, updated_at: four_hours_ago)

      old_submitted_claim = create(:claim, :submitted, updated_at: over_24_hours_ago)

      PurgeUnsubmittedClaimsJob.new.perform

      expect(Claim.exists?(expired_unsubmitted_claim.id)).to eq false

      expect(Claim.exists?(old_submitted_claim.id)).to eq true
      expect(Claim.exists?(active_unsubmitted_claim.id)).to eq true
    end
  end
end
