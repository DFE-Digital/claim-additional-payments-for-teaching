require "rails_helper"

RSpec.shared_examples "an email related to a claim" do |policy|
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

RSpec.describe ClaimMailer, type: :mailer do
  # Characteristics common to all policies
  Policies.all.each do |policy|
    context "with a #{policy} claim" do
      describe "#submitted" do
        let(:claim) { build(:claim, :submitted, policy: policy) }
        let(:mail) { ClaimMailer.submitted(claim) }

        it_behaves_like "an email related to a claim", policy

        it "mentions that claim has been received in the subject and body" do
          expect(mail.subject).to include("been received")
          expect(mail.body.encoded).to include("We've received your claim")
          expect(mail.body.encoded).not_to include("confirm your identity")
        end

        it "adjusts the content for claims that need manual identity confirmation" do
          claim.update!(govuk_verify_fields: [])

          expect(mail.subject).to include("been received")
          expect(mail.body.encoded).to include("We've received your claim")
          expect(mail.body.encoded).to include("confirm your identity")
        end
      end

      describe "#approved" do
        let(:claim) { build(:claim, :approved, policy: policy) }
        let(:mail) { ClaimMailer.approved(claim) }

        it_behaves_like "an email related to a claim", policy

        it "mentions that claim has been approved in the subject and body" do
          expect(mail.subject).to include("approved")
          expect(mail.body.encoded).to include("been approved")
        end
      end

      describe "#rejected" do
        let(:claim) { build(:claim, :submitted, policy: policy) }
        let(:mail) { ClaimMailer.rejected(claim) }

        it_behaves_like "an email related to a claim", policy

        it "mentions that claim has been rejected in the subject and body" do
          expect(mail.subject).to include("rejected")
          expect(mail.body.encoded).to include("not been able to approve")

          ineligible_year = (policy.first_eligible_qts_award_year - 1).to_s(:long)
          expect(mail.body.encoded)
            .to include("completed your initial teacher training in or before the academic year #{ineligible_year}")
        end

        it "changes the ITT reason based on the policy's configured current_academic_year" do
          PolicyConfiguration.for(policy).update!(current_academic_year: "2025/2026")

          ineligible_year = (policy.first_eligible_qts_award_year - 1).to_s(:long)
          expect(mail.body.encoded)
            .to include("completed your initial teacher training in or before the academic year #{ineligible_year}")
        end
      end

      describe "#update_after_three_weeks" do
        let(:claim) { build(:claim, :submitted, policy: policy) }
        let(:mail) { ClaimMailer.update_after_three_weeks(claim) }

        it_behaves_like "an email related to a claim", policy

        it "mentions that the claim is still being reviewed in the subject and body" do
          expect(mail.subject).to include("still reviewing your claim")
          expect(mail.body.encoded).to include("still reviewing your claim")
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
end
