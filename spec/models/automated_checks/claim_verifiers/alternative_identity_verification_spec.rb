require "rails_helper"

RSpec.describe AutomatedChecks::ClaimVerifiers::AlternativeIdentityVerification do
  describe "#perform" do
    context "when the claimant's identity has not been verified" do
      it "doesn't create a task" do
        eligibility = create(
          :further_education_payments_eligibility,
          claimant_identity_verified_at: nil
        )

        claim = create(
          :claim,
          :further_education,
          eligibility:
        )

        expect { described_class.new(claim: claim).perform }.not_to(
          change { claim.tasks.count }
        )
      end
    end

    context "when the claimant's identity has been verified" do
      context "when the task has already been performed" do
        it "doesn't create a new task" do
          eligibility = create(
            :further_education_payments_eligibility,
            claimant_identity_verified_at: DateTime.now
          )

          claim = create(
            :claim,
            :further_education,
            eligibility:
          )

          create(
            :task,
            name: "alternative_identity_verification",
            claim: claim
          )

          expect { described_class.new(claim: claim).perform }.not_to(
            change { claim.tasks.count }
          )
        end
      end
    end
  end
end
