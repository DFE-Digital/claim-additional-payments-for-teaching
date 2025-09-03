require "rails_helper"

RSpec.describe EarlyYearsPaymentsMailer, type: :mailer do
  let(:claim) { build(:claim, :submitted, policy: Policies::EarlyYearsPayments) }

  describe "#progress_update" do
    it "forms correct email" do
      mail = described_class.with(claim:).progress_update

      expect(mail.to).to eql([claim.email_address])
      expect(mail.personalisation[:first_name]).to eql(claim.first_name)
      expect(mail.personalisation[:application_date]).to eql(claim.submitted_at.to_date.to_fs(:long_date))
      expect(mail.personalisation[:ref_number]).to eql(claim.reference)
    end
  end

  describe "#practitioner_claim_reminder" do
    let(:practitioner_email) { "practitioner@example.com" }
    let(:claim) do
      build(:claim, :submitted_by_provider,
        policy: Policies::EarlyYearsPayments,
        practitioner_email_address: practitioner_email,
        first_name: "Jane",
        surname: "Smith",
        reference: "EY123456")
    end

    it "forms correct email" do
      mail = described_class.with(claim:).practitioner_claim_reminder

      expect(mail.to).to eql([practitioner_email])

      personalisation = mail.personalisation
      expect(personalisation[:practitioner_first_name]).to eql(claim.first_name)
      expect(personalisation[:practitioner_second_name]).to eql(claim.surname)
      expect(personalisation[:nursery_name]).to eql(claim.eligibility.eligible_ey_provider.nursery_name)
      expect(personalisation[:ref_number]).to eql(claim.reference)

      # Check that URL points to landing page, not claims endpoint
      expected_url = "https://#{ENV["CANONICAL_HOSTNAME"]}/#{Journeys::EarlyYearsPayment::Practitioner::ROUTING_NAME}/landing-page"
      expect(personalisation[:complete_claim_url]).to eql(expected_url)
    end
  end
end
