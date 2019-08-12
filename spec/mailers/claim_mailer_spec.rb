require "rails_helper"

RSpec.describe ClaimMailer, type: :mailer do
  describe "#submitted" do
    let(:claim) { create(:claim, :submittable) }
    let(:mail) { ClaimMailer.submitted(claim) }

    it "renders the headers" do
      expect(mail.subject).to eq("Your claim was received")
      expect(mail.to).to eq([claim.email_address])
    end

    it "renders the body" do
      expect(mail.body.encoded).to match("We‘ve received your claim to get back the student loan repayments you")
      expect(mail.body.encoded).to match("Your reference number is #{claim.reference}")
    end
  end
end
