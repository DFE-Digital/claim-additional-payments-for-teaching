require "rails_helper"

RSpec.describe Journeys::EarlyYearsPayment::Practitioner::ClaimSubmissionForm do
  before do
    create(:journey_configuration, :early_years_payment_practitioner)
  end

  let(:journey) { Journeys::EarlyYearsPayment::Practitioner }

  let(:journey_session) { create(:early_years_payment_practitioner_session, answers: answers) }
  let(:form) { described_class.new(journey_session: journey_session) }
  let!(:existing_claim) { create(:claim, :early_years_provider_submitted, policy: Policies::EarlyYearsPayments) }

  describe "#save" do
    subject { form.save }

    let(:claim) { form.claim }
    let(:eligibility) { claim.eligibility }
    let(:answers) { build(:early_years_payment_practitioner_answers, :submittable, reference_number: existing_claim.reference) }

    it { is_expected.to be_truthy }

    it "saves some answers into the Claim model" do
      subject
      expect(claim.submitted_at).to be_present
      expect(claim.eligibility_type).to eq "Policies::EarlyYearsPayments::Eligibility"
      expect(claim.first_name).to eq answers.first_name
      expect(claim.surname).to eq answers.surname
      expect(claim.national_insurance_number).to eq answers.national_insurance_number
      expect(claim.date_of_birth).to eq answers.date_of_birth
      expect(claim.banking_name).to eq answers.banking_name
      expect(claim.bank_sort_code).to eq answers.bank_sort_code
      expect(claim.payroll_gender).to eq answers.payroll_gender
      expect(claim.email_address).to eq answers.email_address
    end

    it "saves some answers into the Eligibility model" do
      subject
      expect(eligibility.practitioner_claim_started_at).to be_present
    end
  end
end
