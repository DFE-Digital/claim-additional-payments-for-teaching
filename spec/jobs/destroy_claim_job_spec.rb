require "rails_helper"

RSpec.describe DestroyClaimJob do
  subject(:destroy_claim_job) { described_class.new }

  it { expect(destroy_claim_job).to be_an(ApplicationJob) }

  describe "#perform" do
    let!(:claim) { create(:claim, :submitted, policy: Policies::EarlyCareerPayments) }

    it "destroys the claim" do
      expect { destroy_claim_job.perform(claim.id) }.to change(Claim, :count).by(-1)
    end
  end
end
