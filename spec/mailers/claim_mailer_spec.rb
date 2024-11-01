require "rails_helper"

class SomePolicy; end

RSpec.describe ClaimMailer, type: :mailer do
  shared_examples "an email related to a claim using the generic template" do |policy|
    let(:claim_description) { I18n.t("#{policy.locale_key}.claim_description") }

    it "sets the to address to the claimant's email address" do
      expect(mail.to).to eq([claim.email_address])
    end

    it "sets the GOV.UK Notify reply_to_id according to the policy" do
      expect(mail["reply_to_id"]&.value).to eql(policy.notify_reply_to_id)
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
      expect(mail["reply_to_id"]&.value).to eql(policy.notify_reply_to_id)
    end

    it "includes a personalisation key for claim reference (ref_number)" do
      expect(mail[:personalisation].decoded).to include("ref_number")
      expect(mail[:personalisation].decoded).to include(claim.reference)
    end

    it "includes a personalisation key for 'first_name'" do
      expect(mail[:personalisation].decoded).to include("{:first_name=>\"Jo\"")
      expect(mail.body).to be_empty
    end

    it "includes a personalisation key for 'support_email_address'" do
      support_email_address = I18n.t("#{claim.policy.locale_key}.support_email_address")
      expect(mail[:personalisation].decoded).to include(":support_email_address=>\"#{support_email_address}\"")
    end
  end

  # Characteristics common to all policies
  [Policies::EarlyCareerPayments, Policies::StudentLoans, Policies::LevellingUpPremiumPayments, Policies::InternationalRelocationPayments].each do |policy|
    context "with a #{policy} claim" do
      let!(:journey_configuration) { create(:journey_configuration, policy.to_s.underscore) }

      describe "#submitted" do
        let(:claim) { build(:claim, :submitted, policy: policy) }
        let(:mail) { ClaimMailer.submitted(claim) }

        it_behaves_like "an email related to a claim using GOVUK Notify templates", policy

        context "when EarlyCareerPayments", if: policy == Policies::EarlyCareerPayments do
          it "uses the correct template" do
            expect(mail.template_id).to eq "cb319af7-a769-42e4-8f01-5cbb9fc24846"
          end
        end

        context "when LevellingUpPremiumPayments", if: policy == Policies::LevellingUpPremiumPayments do
          it "uses the correct template" do
            expect(mail.template_id).to eq "0158e1c4-ffa2-4b5e-86f9-0dead4e68587"
          end
        end

        context "when StudentLoans", if: policy == Policies::StudentLoans do
          it "uses the correct template" do
            expect(mail.template_id).to eq "f9e39fcd-301a-4427-9159-6831fd484e39"
          end
        end

        context "when InternationalRelocationPayments", if: policy == Policies::InternationalRelocationPayments do
          it "uses the correct template" do
            expect(mail.template_id).to eq "316d6c56-2354-4cb7-9d1d-3b61bc7e8c59"
          end
        end
      end

      describe "#approved" do
        let(:claim) { build(:claim, :approved, policy: policy) }
        let(:mail) { ClaimMailer.approved(claim) }

        it_behaves_like "an email related to a claim using GOVUK Notify templates", policy

        context "when EarlyCareerPayments", if: policy == Policies::EarlyCareerPayments do
          it "uses the correct template" do
            expect(mail.template_id).to eq "3974db1c-c7dd-44cf-97b9-bb96d211a996"
          end
        end

        context "when LevellingUpPremiumPayments", if: policy == Policies::LevellingUpPremiumPayments do
          it "uses the correct template" do
            expect(mail.template_id).to eq "78e4bf4a-5d4b-4328-9384-116c08183a77"
          end
        end

        context "when StudentLoans", if: policy == Policies::StudentLoans do
          it "uses the correct template" do
            expect(mail.template_id).to eq "2032be01-6aee-4a1a-81ce-cf91e09de8d7"
          end
        end

        context "when InternationalRelocationPayments", if: policy == Policies::InternationalRelocationPayments do
          it "uses the correct template" do
            expect(mail.template_id).to eq "5cf5287f-3bdf-4d0b-b999-b61987b9c39f"
          end
        end
      end

      describe "#rejected" do
        let(:claim) { build(:claim, :rejected, policy: policy) }
        let(:mail) { ClaimMailer.rejected(claim) }
        let(:expected_last_academic_year) { "" }

        it_behaves_like "an email related to a claim using GOVUK Notify templates", policy

        shared_examples "template id and personalisation keys" do
          let(:expected_common_keys) do
            {
              first_name: claim.first_name,
              ref_number: claim.reference,
              support_email_address: I18n.t("#{claim.policy.locale_key}.support_email_address"),
              current_financial_year: (policy == Policies::StudentLoans) ? Policies::StudentLoans.current_financial_year : "",
              last_academic_year: expected_last_academic_year
            }
          end
          let(:all_expected_keys) { expected_common_keys.merge(expected_rejected_reasons_keys) }

          it "uses the correct template" do
            expect(mail.template_id).to eq(expected_template_id)
          end

          it "passes common fields as personalisation keys" do
            expect(mail[:personalisation].unparsed_value).to include(expected_common_keys)
          end

          it "passes rejected reasons as personalisation keys" do
            expect(mail[:personalisation].unparsed_value).to include(expected_rejected_reasons_keys)
          end

          it "does not pass any other personalisation keys" do
            expect(mail[:personalisation].unparsed_value).to match(all_expected_keys)
          end
        end

        context "when EarlyCareerPayments", if: policy == Policies::EarlyCareerPayments do
          let(:expected_template_id) { "b78ffea4-a3d7-4c4a-b0f7-066744c6e79f" }

          let(:expected_rejected_reasons_keys) do
            {
              reason_ineligible_subject: "yes",
              reason_ineligible_year: "no",
              reason_ineligible_school: "no",
              reason_ineligible_qualification: "no",
              reason_induction: "no",
              reason_no_qts_or_qtls: "no",
              reason_duplicate: "no",
              reason_no_response: "no",
              reason_other: "no"
            }
          end

          include_examples "template id and personalisation keys"
        end

        context "when LevellingUpPremiumPayments", if: policy == Policies::LevellingUpPremiumPayments do
          let(:expected_template_id) { "c20e8d85-ef71-4395-8f8b-90fcbd824b86" }

          let(:expected_rejected_reasons_keys) do
            {
              reason_ineligible_subject: "yes",
              reason_ineligible_year: "no",
              reason_ineligible_school: "no",
              reason_ineligible_qualification: "no",
              reason_no_qts_or_qtls: "no",
              reason_duplicate: "no",
              reason_no_response: "no",
              reason_other: "no"
            }
          end

          include_examples "template id and personalisation keys"
        end

        context "when StudentLoans", if: policy == Policies::StudentLoans do
          let(:expected_template_id) { "f719237d-6b2a-42d6-98f2-3d5b6585f32b" }

          let(:expected_rejected_reasons_keys) do
            {
              reason_ineligible_subject: "yes",
              reason_ineligible_year: "no",
              reason_ineligible_school: "no",
              reason_ineligible_qualification: "no",
              reason_no_qts_or_qtls: "no",
              reason_no_repayments_to_slc: "no",
              reason_duplicate: "no",
              reason_no_response: "no",
              reason_other: "no"
            }
          end

          include_examples "template id and personalisation keys"
        end

        context "when InternationalRelocationPayments", if: policy == Policies::InternationalRelocationPayments do
          let(:expected_template_id) { "1edc468c-a1bf-4bea-bb79-042740cd8547" }

          let(:expected_rejected_reasons_keys) do
            {
              reason_duplicate: "yes",
              reason_ineligible_school: "no",
              reason_invalid_bank_details: "no",
              reason_ineligible_visa_or_entry_date: "no",
              reason_ineligible_employment_terms: "no",
              reason_no_response_from_school: "no",
              reason_suspected_fraud: "no",
              reason_information_mismatch_new_details_needed: "no",
              reason_ineligible_previous_residency: "no",
              reason_claimed_last_year: "no"
            }
          end

          include_examples "template id and personalisation keys"
        end

        context "when InternationalRelocationPayments, rejected with claimed_last_year", if: policy == Policies::InternationalRelocationPayments do
          let(:claim) { build(:claim, :rejected, policy: policy, rejected_reasons: {claimed_last_year: "1"}) }

          let(:expected_last_academic_year) { (journey_configuration.current_academic_year - 1).to_s }

          let(:expected_template_id) { "1edc468c-a1bf-4bea-bb79-042740cd8547" }

          let(:expected_rejected_reasons_keys) do
            {
              reason_duplicate: "no",
              reason_ineligible_school: "no",
              reason_invalid_bank_details: "no",
              reason_ineligible_visa_or_entry_date: "no",
              reason_ineligible_employment_terms: "no",
              reason_no_response_from_school: "no",
              reason_suspected_fraud: "no",
              reason_information_mismatch_new_details_needed: "no",
              reason_ineligible_previous_residency: "no",
              reason_claimed_last_year: "yes"
            }
          end

          include_examples "template id and personalisation keys"
        end
      end

      describe "#update_after_three_weeks" do
        let(:claim) { build(:claim, :submitted, policy: policy) }
        let(:mail) { ClaimMailer.update_after_three_weeks(claim) }

        it_behaves_like "an email related to a claim using GOVUK Notify templates", policy

        context "when EarlyCareerPayments", if: policy == Policies::EarlyCareerPayments do
          it "uses the correct template" do
            expect(mail.template_id).to eq "0ef1e702-ea64-43a5-a084-330f2f51836e"
          end
        end

        context "when LevellingUpPremiumPayments", if: policy == Policies::LevellingUpPremiumPayments do
          it "uses the correct template" do
            expect(mail.template_id).to eq "a10322ed-7829-44b2-95c6-d5cc686d2c04"
          end
        end

        context "when StudentLoans", if: policy == Policies::StudentLoans do
          it "uses the correct template" do
            expect(mail.template_id).to eq "c43bac94-67ff-4440-8f26-506eb4c232e8"
          end
        end
      end
    end
  end

  context "unknown claim policy" do
    let(:claim) { instance_double("Claim") }

    before do
      allow(claim).to receive(:policy).and_return(SomePolicy)
    end

    describe "#submitted" do
      it "raises error" do
        expect {
          ClaimMailer.submitted(claim).deliver!
        }.to raise_error(ArgumentError, "Unknown claim policy: SomePolicy")
      end
    end

    describe "#approved" do
      it "raises error" do
        expect {
          ClaimMailer.approved(claim).deliver!
        }.to raise_error(ArgumentError, "Unknown claim policy: SomePolicy")
      end
    end

    describe "#rejected" do
      it "raises error" do
        expect {
          ClaimMailer.rejected(claim).deliver!
        }.to raise_error(ArgumentError, "Unknown claim policy: SomePolicy")
      end
    end

    describe "#update_after_three_weeks" do
      it "raises error" do
        expect {
          ClaimMailer.update_after_three_weeks(claim).deliver!
        }.to raise_error(ArgumentError, "Unknown claim policy: SomePolicy")
      end
    end

    describe "#email_verification" do
      it "raises error" do
        expect {
          ClaimMailer.email_verification(claim, nil).deliver!
        }.to raise_error(ArgumentError, "Unknown claim policy: SomePolicy")
      end
    end

    describe "#early_years_payment_provider_email" do
      it "raises error" do
        expect {
          ClaimMailer.early_years_payment_provider_email(claim, "test@example.com", nil).deliver!
        }.to raise_error(ArgumentError, "Unknown claim policy: SomePolicy")
      end
    end
  end

  describe "#email_verification" do
    let(:mail) { ClaimMailer.email_verification(claim, one_time_password) }
    let(:one_time_password) { 123124 }
    let(:claim) { build(:claim, policy: policy, first_name: "Ellie", email_address: "test@test.com") }

    before { create(:journey_configuration, policy.to_s.underscore) }

    context "with an EarlyCareerPayments claim" do
      let(:policy) { Policies::EarlyCareerPayments }

      it "has personalisation keys for: one time password, validity_duration,first_name and support_email_address" do
        expect(mail[:personalisation].decoded).to eq("{:email_subject=>\"Early-career payment email verification\", :first_name=>\"Ellie\", :one_time_password=>123124, :support_email_address=>\"earlycareerteacherpayments@digital.education.gov.uk\", :validity_duration=>\"15 minutes\"}")
        expect(mail.body).to be_empty
      end
    end

    context "with an LevellingUpPremiumPayments claim" do
      let(:policy) { Policies::LevellingUpPremiumPayments }

      it "has personalisation keys for: one time password, validity_duration,first_name and support_email_address" do
        expect(mail[:personalisation].decoded).to eq("{:email_subject=>\"School targeted retention incentive email verification\", :first_name=>\"Ellie\", :one_time_password=>123124, :support_email_address=>\"schools-targeted.retention-incentive@education.gov.uk\", :validity_duration=>\"15 minutes\"}")
        expect(mail.body).to be_empty
      end
    end
  end

  describe "#early_years_payment_provider_email" do
    let(:mail) { ClaimMailer.early_years_payment_provider_email(claim, one_time_password, email) }
    let(:email) { "test@example.com" }
    let(:one_time_password) { 123124 }
    let(:claim) { build(:claim, policy: policy, email_address: email) }
    let(:policy) { Policies::EarlyYearsPayments }

    before { create(:journey_configuration, :early_years_payment_provider_start) }

    it "has personalisation keys for: magic link" do
      expect(mail[:personalisation].decoded).to eq("{:magic_link=>\"https://#{ENV["CANONICAL_HOSTNAME"]}/early-years-payment-provider/claim?code=123124&email=#{email}\"}")
      expect(mail.body).to be_empty
    end
  end

  describe "#early_years_payment_practitioner_email" do
    let(:mail) { ClaimMailer.early_years_payment_practitioner_email(claim) }
    let(:email_address) { "test@example.com" }
    let(:practitioner_email_address) { "practitioner@example.com" }
    let(:claim) { build(:claim, reference: "TEST123", first_name: "Test", surname: "Practitioner", policy:, email_address:, practitioner_email_address:) }
    let(:policy) { Policies::EarlyYearsPayments }
    let(:nursery_name) { "Test Nursery" }
    let(:eligible_ey_provider) { create(:eligible_ey_provider, nursery_name:) }

    before { create(:journey_configuration, :early_years_payment_provider_start) }
    before { claim.eligibility.update!(nursery_urn: eligible_ey_provider.urn) }

    it "has personalisation keys for: full_name, setting_name, ref_number, complete_claim_url" do
      expected_personalisation = {
        full_name: "Test Practitioner",
        setting_name: "Test Nursery",
        ref_number: "TEST123",
        complete_claim_url: "https://www.example.com/early-years-payment-practitioner/find-reference?skip_landing_page=true&email=practitioner%40example.com"
      }

      expect(mail[:personalisation].unparsed_value).to eql(expected_personalisation)
      expect(mail.body).to be_empty
    end
  end

  describe "#rejected_provider_notification" do
    let(:claim) do
      create(
        :claim,
        :rejected,
        policy: Policies::EarlyYearsPayments
      )
    end

    before do
      claim.eligibility.update!(
        practitioner_first_name: "John",
        practitioner_surname: "Doe"
      )
    end

    it "sends correct email to provider" do
      mail = described_class.rejected_provider_notification(claim)

      expect(mail.to).to eql([claim.eligibility.eligible_ey_provider.primary_key_contact_email_address])
      expect(mail.personalisation[:nursery_name]).to eql(claim.eligibility.eligible_ey_provider.nursery_name)
      expect(mail.personalisation[:ref_number]).to eql(claim.reference)
      expect(mail.personalisation[:practitioner_name]).to eql("John Doe")
      expect(mail.personalisation[:support_email_address]).to eql("earlycareerteacherpayments@digital.education.gov.uk")

      expect(mail.personalisation[:reason_claim_cancelled_by_employer]).to eql("yes")
      expect(mail.personalisation[:reason_six_month_retention_check_failed]).to eql("no")
      expect(mail.personalisation[:reason_duplicate]).to eql("no")
      expect(mail.personalisation[:reason_no_response]).to eql("no")
      expect(mail.personalisation[:reason_other]).to eql("no")
    end
  end
end
