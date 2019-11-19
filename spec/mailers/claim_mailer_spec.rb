require "rails_helper"

RSpec.shared_examples "an email related to a claim" do |policy|
  it "sets the to address to the claimant's email address" do
    expect(mail.to).to eq([claim.email_address])
  end

  it "sets the GOV.UK Notify reply_to_id according to the policy" do
    expect(mail["reply_to_id"].value).to eql(policy.notify_reply_to_id)
  end

  it "mentions the type of claim in the subject" do
    claim_description = I18n.t("#{policy.routing_name.underscore}.claim_description")
    expect(mail.subject).to include(claim_description)
  end
end

RSpec.describe ClaimMailer, type: :mailer do
  describe "#submitted" do
    let(:claim) { create(:claim, :submittable, first_name: "Abraham", surname: "Lincoln") }
    let(:mail) { ClaimMailer.submitted(claim) }

    it_behaves_like "an email related to a claim", StudentLoans

    it "renders the subject" do
      expect(mail.subject).to match("been received")
    end

    it "renders the body" do
      expect(mail.body.encoded).to match("Dear Abraham Lincoln,")
      expect(mail.body.encoded).to match("We've received your claim to get back your student loan repayments.")
      expect(mail.body.encoded).to match("Your unique reference is #{claim.reference}. You will need this if you contact us about your claim.")
    end
  end

  describe "#approved" do
    let(:claim) { create(:claim, :submitted, first_name: "John", middle_name: "Fitzgerald", surname: "Kennedy") }
    let(:mail) { ClaimMailer.approved(claim) }

    it_behaves_like "an email related to a claim", StudentLoans

    it "renders the subject" do
      expect(mail.subject).to match("approved")
      expect(mail.subject).to match("reference number: #{claim.reference}")
    end

    it "renders the body" do
      expect(mail.body.encoded).to match("Dear John Kennedy,")
      expect(mail.body.encoded).to match("been approved")
    end
  end

  describe "#rejected" do
    let(:claim) { create(:claim, :submitted, first_name: "John", middle_name: "Fitzgerald", surname: "Kennedy") }
    let(:mail) { ClaimMailer.rejected(claim) }

    it_behaves_like "an email related to a claim", StudentLoans

    it "renders the subject" do
      expect(mail.subject).to match("rejected")
      expect(mail.subject).to match("reference number: #{claim.reference}")
    end

    it "renders the body" do
      expect(mail.body.encoded).to match("Dear John Kennedy,")
      expect(mail.body.encoded).to match("not been able to approve")
    end
  end

  describe "#payment_confirmation" do
    let(:payment) { create(:payment, :with_figures, net_pay: 500.00, student_loan_repayment: 60, claim: claim) }
    let(:claim) { create(:claim, :submitted, first_name: "John", middle_name: "Fitzgerald", surname: "Kennedy") }
    let(:payment_date_timestamp) { Time.new(2019, 1, 1).to_i }
    let(:mail) { ClaimMailer.payment_confirmation(payment.claim, payment_date_timestamp) }

    it_behaves_like "an email related to a claim", StudentLoans

    it "renders the subject" do
      expect(mail.subject).to match("paying")
      expect(mail.subject).to match("reference number: #{claim.reference}")
    end

    it "renders the body" do
      expect(mail.body.encoded).to include("Dear John Kennedy,")
      expect(mail.body.encoded).to include("We’re paying your claim")
      expect(mail.body.encoded).to include("You will receive £500.00 on or after 1 January 2019")
      expect(mail.body.encoded).to include("Student loan (deducted): £60.00")
    end

    context "when user does not currently have a student loan" do
      let(:payment) { create(:payment, :with_figures, student_loan_repayment: nil, claim: claim) }

      it "shows the right content" do
        expect(mail.body.encoded).to_not include("student loan contribution")
        expect(mail.body.encoded).to_not include("Student loan (deducted)")
      end
    end

    context "when user has a student loan, but has not made a contribution" do
      let(:payment) { create(:payment, :with_figures, student_loan_repayment: 0, claim: claim) }

      it "shows the right content" do
        expect(mail.body.encoded).to include("If you have made a student loan contribution, this is deducted from your payment amount and credited to SLC.")
        expect(mail.body.encoded).to include("Student loan: £0.00")
      end
    end
  end
end
