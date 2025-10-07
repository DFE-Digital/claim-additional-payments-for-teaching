require "rails_helper"

RSpec.describe AutomatedChecks::ClaimVerifiers::FurtherEducationPayments::ProviderVerification do
  describe "#perform" do
    context "when the claimant doesn't have a valid reason for not starting their qualification" do
      it "creates a failed task" do
        claim = create(
          :claim,
          policy: Policies::FurtherEducationPayments,
          eligibility_trait: %i[eligible provider_verification_completed],
          eligibility_attributes: {
            provider_verification_not_started_qualification_reasons: ["no_valid_reason"]
          }
        )

        verifier = described_class.new(claim: claim)

        verifier.perform

        task = claim.tasks.find_by!(name: "fe_provider_verification_v2")

        expect(task.failed?).to be true
        expect(task.manual?).to be false
      end
    end

    context "when the claimant has a valid reason for not starting their qualification" do
      it "doesn't create a task" do
        claim = create(
          :claim,
          policy: Policies::FurtherEducationPayments,
          eligibility_trait: %i[eligible provider_verification_completed],
          eligibility_attributes: {
            provider_verification_not_started_qualification_reasons: ["workload"]
          }
        )

        verifier = described_class.new(claim: claim)

        expect { verifier.perform }.not_to change { claim.tasks.count }
      end
    end
  end
end
