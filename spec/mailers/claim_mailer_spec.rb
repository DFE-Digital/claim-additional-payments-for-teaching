require "rails_helper"

RSpec.describe ClaimMailer, type: :mailer do
  describe "#submitted" do
    let(:claim) { create(:claim, :submittable, first_name: "Abraham", surname: "Lincoln") }
    let(:mail) { ClaimMailer.submitted(claim) }

    it "renders the headers" do
      expect(mail.subject).to eq("Your claim was received")
      expect(mail.to).to eq([claim.email_address])
    end

    it "renders the body" do
      expect(mail.body.encoded).to match("Dear Abraham Lincoln,")
      expect(mail.body.encoded).to match("We've received your application to claim back your student loan repayments for the time you spent at #{claim.eligibility.selected_employment.school_name}.")
      expect(mail.body.encoded).to match("Your unique reference is #{claim.reference}. You will need this if you contact us about your claim.")
    end
  end

  describe "#approved" do
    let(:claim) { create(:claim, :submitted, first_name: "John", middle_name: "Fitzgerald", surname: "Kennedy") }
    let(:mail) { ClaimMailer.approved(claim) }

    it "renders the headers" do
      expect(mail.subject).to eq("Your claim to get your student loan repayments back has been approved, reference number: #{claim.reference}")
      expect(mail.to).to eq([claim.email_address])
    end

    it "renders the body" do
      expect(mail.body.encoded).to match("Dear John Kennedy,")
      expect(mail.body.encoded).to match("Your claim to get your student loan repayments back has been approved.")
      expect(mail.body.encoded).to match("Email studentloanteacherpayment@digital.education.gov.uk giving your reference number: #{claim.reference} if you have any questions.")
    end
  end
end
