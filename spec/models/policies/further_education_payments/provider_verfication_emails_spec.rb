require "rails_helper"

RSpec.describe Policies::FurtherEducationPayments::ProviderVerificationEmails do
  describe "#send_further_education_payment_provider_verification_chase_email" do
    let(:fe_provider) {
      create(
        :school,
        :further_education,
        :fe_eligible,
        name: "Springfield A and M"
      )
    }

    let!(:claim) {
      create(:claim,
        :submitted,
        policy: Policies::FurtherEducationPayments,
        created_at: DateTime.new(2025, 10, 1, 7, 0, 0),
        submitted_at: DateTime.new(2025, 10, 1, 7, 0, 0),
        eligibility: build(
          :further_education_payments_eligibility,
          :eligible,
          school: fe_provider,
          provider_verification_email_last_sent_at: DateTime.new(2025, 10, 1, 7, 0, 0)
        ))
    }

    it "emails the claim provider" do
      travel_to DateTime.new(2025, 10, 1, 7, 0, 0) + 2.weeks do
        perform_enqueued_jobs do
          described_class.new(claim).send_further_education_payment_provider_verification_chase_email
        end

        expect(claim.school.eligible_fe_provider.primary_key_contact_email_address).to(
          have_received_email(
            "9c84a684-b751-449a-bce0-ebe4aa5b187a",
            recipient_name: claim.school.name,
            claimant_name: claim.full_name,
            claim_reference: claim.reference,
            claim_submission_date: "1 October 2025",
            verification_due_date: "29 October 2025",
            verification_url: Journeys::FurtherEducationPayments::Provider::SlugSequence.verify_claim_url(claim)
          )
        )

        expect(claim.eligibility.reload.provider_verification_email_last_sent_at).to eq Time.now
      end
    end
  end
end
