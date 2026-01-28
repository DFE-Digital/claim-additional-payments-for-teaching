require "rails_helper"

RSpec.describe PaymentMailer, type: :mailer do
  context "payment breakdown email for a single claim" do
    shared_examples :single_claim do |policy|
      before { create(:journey_configuration, policy.to_s.underscore) }

      describe "#confirmation" do
        let(:payment) { create(:payment, :confirmed, :with_figures, net_pay: 500.00, student_loan_repayment: 60, postgraduate_loan_repayment: 40, claims: [claim], scheduled_payment_date: Date.parse("2019-01-01")) }
        let(:claim) { build(:claim, :submitted, policy: policy) }
        let(:mail) { PaymentMailer.confirmation(payment) }

        it "sets the to address to the claimant's email address" do
          expect(mail.to).to eq([payment.email_address])
        end

        it "sets the GOV.UK Notify reply_to_id according to the policy" do
          expect(mail.reply_to_id).to eql(policy.notify_reply_to_id)
        end

        it "mentions the type of claim in the subject" do
          claim_description = I18n.t("#{policy.locale_key}.claim_description")
          expect(mail.subject).to include(claim_description)
        end

        it "includes the claim reference in the subject and body" do
          expect(mail.subject).to include("reference number: #{payment.claims.first.reference}")
          expect(mail.body).to include(payment.claims.first.reference)
        end

        it "greets the claimant in the body" do
          expect(mail.body.decoded).to start_with("Dear #{payment.first_name} #{payment.surname},")
        end

        it "mentions that claim is being paid in the subject" do
          expect(mail.subject).to include("paying")
        end

        it "includes the NET pay amount and payment date in the body" do
          expect(mail.body).to include("You will receive £500.00 on Tuesday 1st January 2019")
        end

        it "creates an event" do
          expect { mail.body }.to change {
            Event.where(claim:, name: "email_confirmation_single_sent").count
          }.by(1)
        end

        context "when user does not currently have a student loan or a postgraduate loan" do
          let(:payment) { create(:payment, :confirmed, :with_figures, student_loan_repayment: 0, postgraduate_loan_repayment: 0, claims: [claim]) }

          it "does not mention the content relating to student loan deductions" do
            expect(mail.body).to_not include("Student loan contribution:")
            expect(mail.body).to_not include("The Student Loans Company has told us that you’re currently repaying a student loan. This amount is deducted from your payment and goes towards repaying your loan.")
          end

          it "does not mention the content relating to postgraduate loan deductions" do
            expect(mail.body).to_not include("Postgraduate Master’s or PhD loan contribution:")
            expect(mail.body).to_not include("The Student Loans Company has told us that you’re currently repaying a Postgraduate Master’s Loan or Postgraduate Doctoral Loan. This amount is deducted from your payment and goes towards repaying your loan.")
          end
        end

        context "when user has a student loan and a postgraduate loan" do
          let(:payment) { create(:payment, :confirmed, :with_figures, student_loan_repayment: 10, postgraduate_loan_repayment: 8, claims: [claim]) }

          it "mentions the student loan deduction content and lists their contribution" do
            expect(mail.body).to include("This payment is treated as pay and is therefore subject to a student loan contribution, if applicable.")
            expect(mail.body).to include("Student loan contribution: £10.00")
            expect(mail.body).to include("The Student Loans Company has told us that you’re currently repaying a student loan. This amount is deducted from your payment and goes towards repaying your loan.")
          end
          it "mentions the postgraduate loan deduction content and lists their contribution" do
            expect(mail.body).to include("This payment is treated as pay and is therefore subject to a student loan contribution, if applicable.")
            expect(mail.body).to include("Postgraduate Master’s or PhD loan contribution: £8.00")
            expect(mail.body).to include("The Student Loans Company has told us that you’re currently repaying a Postgraduate Master’s Loan or Postgraduate Doctoral Loan. This amount is deducted from your payment and goes towards repaying your loan.")
          end
        end

        context "when user has a student loan and no postgraduate loan" do
          let(:payment) { create(:payment, :confirmed, :with_figures, student_loan_repayment: 10, postgraduate_loan_repayment: 0, claims: [claim]) }

          it "mentions the student loan deduction content and lists their contribution" do
            expect(mail.body).to include("Student loan contribution: £10.00")
            expect(mail.body).to include("The Student Loans Company has told us that you’re currently repaying a student loan. This amount is deducted from your payment and goes towards repaying your loan.")
          end
          it "does not include the postgraduate loan deduction content" do
            expect(mail.body).not_to include("Postgraduate Master’s or PhD loan contribution")
            expect(mail.body).not_to include("The Student Loans Company has told us that you’re currently repaying a Postgraduate Master’s Loan or Postgraduate Doctoral Loan. This amount is deducted from your payment and goes towards repaying your loan.")
          end
        end

        context "when user has no student loan and a postgraduate loan" do
          let(:payment) { create(:payment, :confirmed, :with_figures, student_loan_repayment: 0, postgraduate_loan_repayment: 8, claims: [claim]) }

          it "does not include the student loan deduction content" do
            expect(mail.body).not_to include("Student loan contribution")
            expect(mail.body).not_to include("The Student Loans Company has told us that you’re currently repaying a student loan. This amount is deducted from your payment and goes towards repaying your loan.")
          end
          it "includes the postgraduate loan deduction content" do
            expect(mail.body).to include("Postgraduate Master’s or PhD loan contribution: £8.00")
            expect(mail.body).to include("The Student Loans Company has told us that you’re currently repaying a Postgraduate Master’s Loan or Postgraduate Doctoral Loan. This amount is deducted from your payment and goes towards repaying your loan.")
          end
        end
      end
    end

    # Characteristics common to all policies
    Policies.all.select(&:active?).each do |policy|
      describe "for a #{policy} payment" do
        include_examples :single_claim, policy
      end
    end
  end

  # NOTE: only happens for Targeted Retention Incentive + TSLR
  context "payment breakdown email with multiple claims" do
    shared_examples :multiple_claims do |second_claim_policy|
      describe "#confirmation" do
        let(:payment) { create(:payment, :confirmed, :with_figures, net_pay: 2500.00, student_loan_repayment: 60, claims: claims, scheduled_payment_date: Date.parse("2019-01-01")) }
        let(:teacher_reference_number) { "1234567" }
        let(:claims) do
          personal_details = {
            national_insurance_number: "JM603818B",
            bank_sort_code: "112233",
            bank_account_number: "95928482",
            building_society_roll_number: nil
          }
          [
            build(:claim, :approved, personal_details.merge(eligibility_attributes: {award_amount: 500, teacher_reference_number: teacher_reference_number})),
            build(:claim, :approved, personal_details.merge(policy: second_claim_policy, eligibility_attributes: {award_amount: 5_000, teacher_reference_number: teacher_reference_number}))
          ]
        end
        let(:mail) { PaymentMailer.confirmation(payment) }

        it "sets the to address to the claimant's email address" do
          expect(mail.to).to eq([payment.email_address])
        end

        it "sets the GOV.UK Notify reply_to_id to be the generic service email address" do
          expect(mail.reply_to_id).to eql(ApplicationMailer::GENERIC_NOTIFY_REPLY_TO_ID)
        end

        it "greets the claimant in the body" do
          expect(mail.body.decoded).to start_with("Dear #{payment.first_name} #{payment.surname},")
        end

        it "includes the NET pay amount and payment date in the body" do
          expect(mail.body).to include("You will receive £2,500.00 on Tuesday 1st January 2019")
        end

        it "mentions the type of claim in the body" do
          expect(mail.body).to include(I18n.t("#{claims[0].policy.locale_key}.claim_amount_description"))
          expect(mail.body).to include(I18n.t("#{claims[1].policy.locale_key}.claim_amount_description"))
        end

        it "includes the claims' references in the body" do
          expect(mail.body).to include(claims[0].reference)
          expect(mail.body).to include(claims[1].reference)
        end

        it "includes the amount claimed for each claim" do
          expect(mail.body).to include("Additional payment for teaching: £5,000.00")
          expect(mail.body).to include("Student loan repayments you’ve claimed back: £500.00")
        end

        it "creates an event for each claim" do
          expect { mail.body }.to change {
            Event.count
          }.by(2)
        end

        context "when user does not currently have a student loan or a postgraduate loan" do
          let(:payment) { create(:payment, :confirmed, :with_figures, student_loan_repayment: 0, postgraduate_loan_repayment: 0, claims: claims) }

          it "does not mention the content relating to student loan deductions" do
            expect(mail.body).to_not include("Student loan contribution:")
            expect(mail.body).to_not include("The Student Loans Company has told us that you’re currently repaying a student loan. This amount is deducted from your payment and goes towards repaying your loan.")
          end

          it "does not mention the content relating to postgraduate loan deductions" do
            expect(mail.body).to_not include("Postgraduate Master’s or PhD loan contribution:")
            expect(mail.body).to_not include("The Student Loans Company has told us that you’re currently repaying a Postgraduate Master’s Loan or Postgraduate Doctoral Loan. This amount is deducted from your payment and goes towards repaying your loan.")
          end
        end

        context "when user has a student loan and a postgraduate loan" do
          let(:payment) { create(:payment, :confirmed, :with_figures, student_loan_repayment: 10, postgraduate_loan_repayment: 8, claims: claims) }

          it "mentions the student loan deduction content and lists their contribution" do
            expect(mail.body).to include("This payment is treated as pay and is therefore subject to a student loan contribution, if applicable.")
            expect(mail.body).to include("Student loan contribution: £10.00")
          end

          it "includes the postgraduate loan deduction content" do
            expect(mail.body).to include("Postgraduate Master’s or PhD loan contribution: £8.00")
            expect(mail.body).to include("The Student Loans Company has told us that you’re currently repaying a Postgraduate Master’s Loan or Postgraduate Doctoral Loan. This amount is deducted from your payment and goes towards repaying your loan.")
          end
        end

        context "when user has a student loan and no postgraduate loan" do
          let(:payment) { create(:payment, :confirmed, :with_figures, student_loan_repayment: 10, postgraduate_loan_repayment: 0, claims: claims) }

          it "mentions the student loan deduction content and lists their contribution" do
            expect(mail.body).to include("Student loan contribution: £10.00")
            expect(mail.body).to include("The Student Loans Company has told us that you’re currently repaying a student loan. This amount is deducted from your payment and goes towards repaying your loan.")
          end
          it "does not include the postgraduate loan deduction content" do
            expect(mail.body).not_to include("Postgraduate Master’s or PhD loan contribution")
            expect(mail.body).not_to include("The Student Loans Company has told us that you’re currently repaying a Postgraduate Master’s Loan or Postgraduate Doctoral Loan. This amount is deducted from your payment and goes towards repaying your loan.")
          end
        end

        context "when user has no student loan and a postgraduate loan" do
          let(:payment) { create(:payment, :confirmed, :with_figures, student_loan_repayment: 0, postgraduate_loan_repayment: 8, claims: claims) }

          it "does not include the student loan deduction content" do
            expect(mail.body).not_to include("Student loan contribution")
            expect(mail.body).not_to include("The Student Loans Company has told us that you’re currently repaying a student loan. This amount is deducted from your payment and goes towards repaying your loan.")
          end
          it "includes the postgraduate loan deduction content" do
            expect(mail.body).to include("Postgraduate Master’s or PhD loan contribution: £8.00")
            expect(mail.body).to include("The Student Loans Company has told us that you’re currently repaying a Postgraduate Master’s Loan or Postgraduate Doctoral Loan. This amount is deducted from your payment and goes towards repaying your loan.")
          end
        end
      end
    end

    [Policies::EarlyCareerPayments, Policies::TargetedRetentionIncentivePayments].each do |policy|
      describe "for a payment with a TSLR and a #{policy} claim" do
        include_examples :multiple_claims, policy
      end
    end
  end
end
