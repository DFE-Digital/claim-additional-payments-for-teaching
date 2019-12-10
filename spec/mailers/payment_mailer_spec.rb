require "rails_helper"

RSpec.describe PaymentMailer, type: :mailer do
  # Characteristics common to all policies
  Policies.all.each do |policy|
    context "with a #{policy} claim" do
      describe "#confirmation" do
        let(:payment) { build(:payment, :with_figures, net_pay: 500.00, student_loan_repayment: 60, claim: claim) }
        let(:claim) { build(:claim, :submitted, policy: policy) }
        let(:payment_date_timestamp) { Time.new(2019, 1, 1).to_i }
        let(:mail) { PaymentMailer.confirmation(payment, payment_date_timestamp) }

        it "sets the to address to the claimant's email address" do
          expect(mail.to).to eq([payment.email_address])
        end

        it "sets the GOV.UK Notify reply_to_id according to the policy" do
          expect(mail["reply_to_id"].value).to eql(policy.notify_reply_to_id)
        end

        it "mentions the type of claim in the subject and body" do
          claim_description = I18n.t("#{policy.routing_name.underscore}.claim_description")
          expect(mail.subject).to include(claim_description)
          expect(mail.body.encoded).to include(claim_description)
        end

        it "includes the claim reference in the subject and body" do
          expect(mail.subject).to include("reference number: #{payment.claim.reference}")
          expect(mail.body.encoded).to include(payment.claim.reference)
        end

        it "greets the claimant in the body" do
          expect(mail.body.encoded).to start_with("Dear #{payment.first_name} #{payment.surname},")
        end

        it "mentions that claim is being paid in the subject and body" do
          expect(mail.subject).to include("paying")
          expect(mail.body.encoded).to include("We’re paying your claim")
        end

        it "includes the NET pay amount and payment date in the body" do
          expect(mail.body.encoded).to include("You will receive £500.00 on or after 1 January 2019")
        end

        context "when user does not currently have a student loan" do
          let(:payment) { build(:payment, :with_figures, student_loan_repayment: nil, claim: claim) }

          it "does not mention the content relating to student loan deductions" do
            expect(mail.body.encoded).to_not include("student loan contribution")
          end
        end

        context "when user has a student loan" do
          let(:payment) { build(:payment, :with_figures, student_loan_repayment: 10, claim: claim) }

          it "mentions the student loan deduction content and lists their contribution" do
            expect(mail.body.encoded).to include("This payment is treated as pay and is therefore subject to a student loan contribution, if applicable.")
            expect(mail.body.encoded).to include("Student loan contribution: £10.00")
          end
        end
      end
    end
  end
end
