require "rails_helper"

RSpec.describe Journeys::EarlyYearsPayment::Provider::Authenticated::ClaimSubmissionForm do
  before do
    create(:journey_configuration, :early_years_payment_provider_authenticated)
  end

  let(:journey) { Journeys::EarlyYearsPayment::Provider::Authenticated }

  let(:journey_session) { create(:early_years_payment_provider_authenticated_session, answers: answers) }
  let(:form) { described_class.new(journey_session: journey_session) }

  describe "#save" do
    subject { form.save }

    let(:claim) { form.claim }
    let(:eligibility) { claim.eligibility }
    let(:answers) { build(:early_years_payment_provider_authenticated_answers, :submittable) }

    it { is_expected.to be_truthy }

    it "saves some answers into the Claim model" do
      subject
      expect(claim.email_address).to be nil
      expect(claim.submitted_at).to be_nil
      expect(claim.eligibility_type).to eq "Policies::EarlyYearsPayments::Eligibility"
      expect(claim.first_name).to eq answers.first_name
      expect(claim.surname).to eq answers.surname
      expect(claim.paye_reference).to eq answers.paye_reference
      expect(claim.practitioner_email_address).to eq answers.practitioner_email_address
      expect(claim.provider_contact_name).to eq "John Doe"
    end

    it "saves some answers into the Eligibility model" do
      subject
      expect(eligibility.nursery_urn).to eq answers.nursery_urn
      expect(eligibility.child_facing_confirmation_given).to eq answers.child_facing_confirmation_given
      expect(eligibility.returning_within_6_months).to eq answers.returning_within_6_months
      expect(eligibility.start_date).to eq answers.start_date
      expect(eligibility.provider_claim_submitted_at).to be_present
      expect(eligibility.provider_email_address).to eq "provider@example.com"
      expect(eligibility.practitioner_first_name).to eq answers.first_name
      expect(eligibility.practitioner_surname).to eq answers.surname
    end

    it "sends a notify email to the practitioner" do
      allow(ClaimVerifierJob).to receive(:perform_later)

      perform_enqueued_jobs { subject }

      expect(claim.practitioner_email_address).to(
        have_received_email(
          "ef21f1d7-8a5c-4261-80b9-e1b78f844575",
          full_name: claim.full_name,
          setting_name: claim.eligibility.eligible_ey_provider.nursery_name,
          ref_number: claim.reference,
          complete_claim_url: "https://www.example.com/early-years-payment-practitioner/find-reference?skip_landing_page=true&email=johndoe%40example.com"
        )
      )
    end
  end
end
