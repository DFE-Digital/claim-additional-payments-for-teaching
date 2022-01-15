require "rails_helper"

RSpec.describe ClaimMailer, type: :mailer do
  shared_examples "an email related to a claim using the generic template" do |policy|
    let(:claim_description) { I18n.t("#{policy.locale_key}.claim_description") }

    it "sets the to address to the claimant's email address" do
      expect(mail.to).to eq([claim.email_address])
    end

    it "sets the GOV.UK Notify reply_to_id according to the policy" do
      expect(mail["reply_to_id"].value).to eql(policy.notify_reply_to_id)
    end

    it "mentions the type of claim in the subject and body" do
      expect(mail.subject).to include(claim_description)
      expect(mail.body.encoded).to include(claim_description)
    end

    it "includes the claim reference in the subject and body" do
      expect(mail.subject).to include("reference number: #{claim.reference}")
      expect(mail.body.encoded).to include(claim.reference)
    end

    it "greets the claimant in the body" do
      expect(mail.body.encoded).to start_with("Dear #{claim.first_name} #{claim.surname},")
    end
  end

  shared_examples "an email related to a claim using GOVUK Notify templates" do |policy|
    let(:claim_description) { I18n.t("#{policy.locale_key}.claim_description") }

    it "sets the to address to the claimant's email address" do
      expect(mail.to).to eq([claim.email_address])
    end

    it "sets the GOV.UK Notify reply_to_id according to the policy" do
      expect(mail["reply_to_id"].value).to eql(policy.notify_reply_to_id)
    end

    it "includes a personalisation key for claim reference (ref_number)" do
      expect(mail[:personalisation].decoded).to include("ref_number")
      expect(mail[:personalisation].decoded).to include(claim.reference)
    end

    it "includes a personalisation key for 'first_name'" do
      expect(mail[:personalisation].decoded).to include("{:first_name=>\"Jo\"")
      expect(mail.body.encoded).to be_empty
    end

    it "includes a personalisation key for 'support_email_address'" do
      support_email_address = I18n.t("#{claim.policy.locale_key}.support_email_address")
      expect(mail[:personalisation].decoded).to include(":support_email_address=>\"#{support_email_address}\"}")
    end
  end

  # Characteristics common to all policies
  [EarlyCareerPayments, StudentLoans].each do |policy|
    context "with a #{policy} claim" do
      describe "#submitted" do
        let(:claim) { build(:claim, :submitted, policy: policy) }
        let(:mail) { ClaimMailer.submitted(claim) }

        it_behaves_like "an email related to a claim using GOVUK Notify templates", policy

        context "when EarlyCareerPayments", if: policy == EarlyCareerPayments do
          it "uses the correct template" do
            expect(mail[:template_id].decoded).to eq "cb319af7-a769-42e4-8f01-5cbb9fc24846"
          end
        end

        context "when StudentLoans", if: policy == StudentLoans do
          it "uses the correct template" do
            expect(mail[:template_id].decoded).to eq "f9e39fcd-301a-4427-9159-6831fd484e39"
          end
        end
      end

      describe "#approved" do
        let(:claim) { build(:claim, :approved, policy: policy) }
        let(:mail) { ClaimMailer.approved(claim) }

        it_behaves_like "an email related to a claim using the generic template", policy

        it "mentions that claim has been approved in the subject and body" do
          expect(mail.subject).to include("approved")
          expect(mail.body.encoded).to include("been approved")
        end
      end

      describe "#rejected" do
        let(:claim) { build(:claim, :submitted, policy: policy) }
        let(:mail) { ClaimMailer.rejected(claim) }

        it_behaves_like "an email related to a claim using the generic template", policy

        it "mentions that claim has been rejected in the subject and body" do
          expect(mail.subject).to include("rejected")
          expect(mail.body.encoded).to include("not been able to approve")

          expect(mail.body.encoded)
            .to include("We have not been able to approve your application")
        end

        it "changes the ITT reason based on the policy's configured current_academic_year" do
          PolicyConfiguration.for(policy).update!(current_academic_year: "2025/2026")

          expect(mail.body.encoded)
            .to include("We have not been able to approve your application")
        end
      end

      describe "#update_after_three_weeks" do
        let(:claim) { build(:claim, :submitted, policy: policy) }
        let(:mail) { ClaimMailer.update_after_three_weeks(claim) }

        it_behaves_like "an email related to a claim using the generic template", policy

        it "mentions that the claim is still being reviewed in the subject and body" do
          expect(mail.subject).to include("still reviewing your application")
          expect(mail.body.encoded).to include("We're still reviewing your application")
        end
      end
    end
  end

  [MathsAndPhysics].each do |policy|
    context "with a #{policy} claim" do
      describe "#submitted" do
        let(:claim) { build(:claim, :submitted, policy: policy) }
        let(:mail) { ClaimMailer.submitted(claim) }

        it_behaves_like "an email related to a claim using the generic template", policy

        it "mentions that claim has been received in the subject and body" do
          expect(mail.subject).to include("been received")
          expect(mail.body.encoded).to include("We've received your application")
        end
      end

      describe "#approved" do
        let(:claim) { build(:claim, :approved, policy: policy) }
        let(:mail) { ClaimMailer.approved(claim) }

        it_behaves_like "an email related to a claim using the generic template", policy

        it "mentions that claim has been approved in the subject and body" do
          expect(mail.subject).to include("approved")
          expect(mail.body.encoded).to include("been approved")
        end
      end

      describe "#rejected" do
        let(:claim) { build(:claim, :submitted, policy: policy) }
        let(:mail) { ClaimMailer.rejected(claim) }

        it_behaves_like "an email related to a claim using the generic template", policy

        it "mentions that claim has been rejected in the subject and body" do
          expect(mail.subject).to include("rejected")
          expect(mail.body.encoded).to include("not been able to approve")

          expect(mail.body.encoded)
            .to include("We have not been able to approve your application")
        end

        it "changes the ITT reason based on the policy's configured current_academic_year" do
          PolicyConfiguration.for(policy).update!(current_academic_year: "2025/2026")

          expect(mail.body.encoded)
            .to include("We have not been able to approve your application")
        end
      end

      describe "#update_after_three_weeks" do
        let(:claim) { build(:claim, :submitted, policy: policy) }
        let(:mail) { ClaimMailer.update_after_three_weeks(claim) }

        it_behaves_like "an email related to a claim using the generic template", policy

        it "mentions that the claim is still being reviewed in the subject and body" do
          expect(mail.subject).to include("still reviewing your application")
          expect(mail.body.encoded).to include("We're still reviewing your application")
        end
      end
    end
  end

  context "with a StudentLoans claim" do
    describe "#rejected" do
      let(:claim) { build(:claim, :submitted, policy: StudentLoans) }
      let(:mail) { ClaimMailer.rejected(claim) }

      it "mentions “the eligible-school during the financial year” reason" do
        # Based on the current academic year set by the policy_configurations.yml fixtures
        expect(mail.body.encoded).to include("you did not teach at an eligible school between 6 April 2024 and 5 April 2025")
      end

      it "changes the financial year based on the policy's configured current_academic_year" do
        policy_configurations(:student_loans).update!(current_academic_year: "2019/2020")

        expect(mail.body.encoded)
          .to include("you did not teach at an eligible school between 6 April 2018 and 5 April 2019")
      end
    end
  end

  context "with an EarlyCareerPayments claim" do
    describe "#email_verification" do
      let(:claim) { build(:claim, policy: EarlyCareerPayments, first_name: "Ellie") }
      let(:mail) { ClaimMailer.email_verification(claim, one_time_password) }
      let(:one_time_password) { 123124 }

      it "has personalisation keys for: one time password, validity_duration,first_name and support_email_address" do
        expect(mail[:personalisation].decoded).to eq("{:email_subject=>\"Early-career payment email verification\", :first_name=>\"Ellie\", :one_time_password=>123124, :support_email_address=>\"earlycareerteacherpayments@digital.education.gov.uk\", :validity_duration=>\"15 minutes\"}")
        expect(mail.body.encoded).to be_empty
      end
    end
  end
end
