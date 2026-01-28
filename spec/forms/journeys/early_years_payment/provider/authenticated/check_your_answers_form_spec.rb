require "rails_helper"

RSpec.describe Journeys::EarlyYearsPayment::Provider::Authenticated::CheckYourAnswersForm, type: :model do
  let(:journey) { Journeys::EarlyYearsPayment::Provider::Authenticated }
  let(:journey_session) { create(:early_years_payment_provider_authenticated_session, answers:) }
  let(:provider_contact_name) { nil }

  let(:nursery) do
    create(:eligible_ey_provider, :with_secondary_contact_email_address)
  end

  let(:answers) do
    build(
      :early_years_payment_provider_authenticated_answers,
      :submittable,
      provider_contact_name: nil,
      nursery_urn: nursery.urn
    )
  end

  let(:params) do
    ActionController::Parameters.new(
      claim: {
        provider_contact_name:
      }
    )
  end

  subject do
    described_class.new(journey_session:, journey:, params:)
  end

  describe "validations" do
    it do
      is_expected.not_to(
        allow_value(provider_contact_name)
        .for(:provider_contact_name)
        .with_message("You cannot submit this claim without providing your full name")
      )
    end
  end

  describe "#save" do
    let(:provider_contact_name) { "John Doe" }

    it "updates the journey session" do
      expect { expect(subject.save).to be(true) }.to(
        change { journey_session.reload.answers.provider_contact_name }.to("John Doe")
      )
    end

    let(:claim) { Claim.last }
    let(:eligibility) { claim.eligibility }

    it "returns truthy" do
      expect(subject.save).to be_truthy
    end

    it "saves some answers into the Claim model" do
      subject.save

      expect(claim.policy).to eql(Policies::EarlyYearsPayments)
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
      subject.save

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

      perform_enqueued_jobs { subject.save }

      expect(claim.practitioner_email_address).to(
        have_received_email(
          "ef21f1d7-8a5c-4261-80b9-e1b78f844575",
          full_name: claim.full_name,
          setting_name: claim.eligibility.eligible_ey_provider.nursery_name,
          ref_number: claim.reference,
          complete_claim_url: "https://www.example.com/early-years-payment-practitioner/landing-page"
        )
      )
    end

    it "creates an event practitioner email sent" do
      allow(ClaimVerifierJob).to receive(:perform_later)

      expect { perform_enqueued_jobs { subject.save } }.to change {
        Event.where(name: "email_ey_practitioner_sent").count
      }.by(1)
    end

    it "doesn't send the claim submitted notification email" do
      allow(ClaimVerifierJob).to receive(:perform_later)

      perform_enqueued_jobs { subject.save }

      expect(claim.practitioner_email_address).not_to(
        have_received_email("f97480c8-7869-4af6-b50c-413929b8cc88")
      )
    end

    it "sends a notify email to the provider" do
      primary_contact_email = nursery.primary_key_contact_email_address
      secondary_contact_email = nursery.secondary_contact_email_address

      allow(ClaimVerifierJob).to receive(:perform_later)

      perform_enqueued_jobs { subject.save }

      expect(primary_contact_email).to(
        have_received_email(
          "149c5999-12fb-4b99-aff5-23a7c3302783",
          nursery_name: nursery.nursery_name,
          practitioner_first_name: answers.first_name,
          practitioner_last_name: answers.surname,
          ref_number: claim.reference
        )
      )

      expect(secondary_contact_email).to(
        have_received_email(
          "149c5999-12fb-4b99-aff5-23a7c3302783",
          nursery_name: nursery.nursery_name,
          practitioner_first_name: answers.first_name,
          practitioner_last_name: answers.surname,
          ref_number: claim.reference
        )
      )
    end

    it "create a claim_submitted Event" do
      expect { subject.save }.to(
        change { Event.where(name: "claim_submitted").count }.by(1)
      )
    end
  end
end
