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
end
