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
      expect(claim.email_address).to eq answers.email_address
      expect(claim.submitted_at).to be_present
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
      expect(eligibility.first_job_within_6_months).to eq answers.first_job_within_6_months
      expect(eligibility.start_date).to eq answers.start_date
    end
  end
end
