require "rails_helper"

RSpec.describe AutoApproveClaimJob do
  subject(:auto_approve_claim_job) { described_class.new }

  it { expect(described_class.new).to be_an(ApplicationJob) }

  describe "#perform" do
    subject(:run_job) { auto_approve_claim_job.perform(claim) }
    let(:claim) { create(:claim, :submitted) }

    before do
      allow_any_instance_of(ClaimAutoApproval).to receive(:eligible?).and_return(eligible?)
    end

    context "when the claim is eligible for auto-approval" do
      let(:eligible?) { true }

      it "creates an approval decision" do
        expect { run_job }.to change { claim.reload.latest_decision }.from(nil)
          .to have_attributes(approved: true, notes: "Auto-approved")
      end
    end

    context "when the claim is not eligible for auto-approval" do
      let(:eligible?) { false }

      it "doesn't create an approval decision" do
        expect { run_job }.not_to change { claim.reload.latest_decision }.from(nil)
      end
    end
  end
end
