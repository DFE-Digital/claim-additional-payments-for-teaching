require "rails_helper"

RSpec.describe PaymentMailer, type: :mailer do
  # Characteristics common to all policies
  Policies.all.each do |policy|
    context "with a payment with a single #{policy} claim" do
      describe "#confirmation" do
        let(:payment) { create(:payment, :with_figures, net_pay: 500.00, student_loan_repayment: 60, claims: [claim], scheduled_payment_date: Date.parse("2019-01-01")) }
        let(:claim) { build(:claim, :submitted, policy: policy) }
        let(:mail) { PaymentMailer.confirmation(payment) }

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
          expect(mail.subject).to include("reference number: #{payment.claims.first.reference}")
          expect(mail.body.encoded).to include(payment.claims.first.reference)
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
          let(:payment) { create(:payment, :with_figures, student_loan_repayment: nil, claims: [claim]) }

          it "does not mention the content relating to student loan deductions" do
            expect(mail.body.encoded).to_not include("student loan contribution")
          end
        end

        context "when user has a student loan" do
          let(:payment) { create(:payment, :with_figures, student_loan_repayment: 10, claims: [claim]) }

          it "mentions the student loan deduction content and lists their contribution" do
            expect(mail.body.encoded).to include("This payment is treated as pay and is therefore subject to a student loan contribution, if applicable.")
            expect(mail.body.encoded).to include("Student loan contribution: £10.00")
          end
        end
      end
    end
  end

  context "with a payment with multiple claims" do
    describe "#confirmation" do
      let(:payment) { create(:payment, :with_figures, net_pay: 2500.00, student_loan_repayment: 60, claims: claims, scheduled_payment_date: Date.parse("2019-01-01")) }
      let(:student_loans_eligibility) { build(:student_loans_eligibility, :eligible, student_loan_repayment_amount: 500) }
      let(:claims) do
        personal_details = {
          national_insurance_number: "JM603818B",
          teacher_reference_number: "1234567",
          bank_sort_code: "112233",
          bank_account_number: "95928482",
          building_society_roll_number: nil,
        }
        [
          build(:claim, :approved, personal_details.merge(eligibility: student_loans_eligibility)),
          build(:claim, :approved, personal_details.merge(policy: MathsAndPhysics)),
        ]
      end
      let(:mail) { PaymentMailer.confirmation(payment) }

      it "sets the to address to the claimant's email address" do
        expect(mail.to).to eq([payment.email_address])
      end

      it "sets the GOV.UK Notify reply_to_id to be the generic service email address" do
        expect(mail["reply_to_id"].value).to eql(ApplicationMailer::GENERIC_NOTIFY_REPLY_TO_ID)
      end

      it "greets the claimant in the body" do
        expect(mail.body.encoded).to start_with("Dear #{payment.first_name} #{payment.surname},")
      end

      it "mentions that claims are being paid in the body" do
        expect(mail.body.encoded).to include("We’re paying:")
      end

      it "includes the NET pay amount and payment date in the body" do
        expect(mail.body.encoded).to include("You will receive £2,500.00 on or after 1 January 2019")
      end

      it "mentions the type of claim in the body" do
        expect(mail.body.encoded).to include(I18n.t("#{claims[0].policy.routing_name.underscore}.claim_description"))
        expect(mail.body.encoded).to include(I18n.t("#{claims[1].policy.routing_name.underscore}.claim_description"))
      end

      it "includes the claims' references in the body" do
        expect(mail.body.encoded).to include(claims[0].reference)
        expect(mail.body.encoded).to include(claims[1].reference)
      end

      it "includes the support email address for each policy" do
        expect(mail.body.encoded).to include(I18n.t("maths_and_physics.support_email_address"))
        expect(mail.body.encoded).to include(I18n.t("student_loans.support_email_address"))
      end

      it "includes the amount claimed for each claim" do
        expect(mail.body.encoded).to include("Payment for teaching maths or physics: £2,000.00")
        expect(mail.body.encoded).to include("Student loan repayments you’ve claimed back: £500.00")
      end

      context "when user does not currently have a student loan" do
        let(:payment) { create(:payment, :with_figures, student_loan_repayment: nil, claims: claims) }

        it "does not mention the content relating to student loan deductions" do
          expect(mail.body.encoded).to_not include("student loan contribution")
        end
      end

      context "when user has a student loan" do
        let(:payment) { create(:payment, :with_figures, student_loan_repayment: 10, claims: claims) }

        it "mentions the student loan deduction content and lists their contribution" do
          expect(mail.body.encoded).to include("This payment is treated as pay and is therefore subject to a student loan contribution, if applicable.")
          expect(mail.body.encoded).to include("Student loan contribution: £10.00")
        end
      end
    end
  end
end
