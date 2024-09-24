require "rails_helper"

RSpec.describe FurtherEducationPayments::ProviderVerificationChaseEmailJob do
  around do |example|
    travel_to DateTime.new(2024, 10, 22, 8, 0, 0) do
      example.run
    end
  end

  describe "#perform" do
    let!(:claim_with_no_provider_email_sent) {
      create(:claim,
        :submitted,
        policy: Policies::FurtherEducationPayments,
        eligibility: build(
          :further_education_payments_eligibility,
          :eligible,
          provider_verification_email_last_sent_at: nil
        ))
    }

    let!(:claim_with_provider_email_sent_over_3_weeks_ago) {
      create(:claim,
        :submitted,
        policy: Policies::FurtherEducationPayments,
        eligibility: build(
          :further_education_payments_eligibility,
          :eligible,
          provider_verification_email_last_sent_at: DateTime.new(2024, 10, 1, 7, 0, 0)
        ))
    }

    let!(:claim_with_provider_email_sent_less_than_3_weeks_ago) {
      create(:claim,
        :submitted,
        policy: Policies::FurtherEducationPayments,
        eligibility: build(
          :further_education_payments_eligibility,
          :eligible,
          provider_verification_email_last_sent_at: DateTime.new(2024, 10, 15, 7, 0, 0)
        ))
    }

    let!(:claim_with_provider_email_sent_over_3_weeks_ago_verified) {
      create(:claim,
        :submitted,
        policy: Policies::FurtherEducationPayments,
        eligibility: build(
          :further_education_payments_eligibility,
          :eligible,
          :verified,
          provider_verification_email_last_sent_at: DateTime.new(2024, 10, 1, 7, 0, 0)
        ))
    }

    before do
      allow(ClaimMailer).to(
        receive(:further_education_payment_provider_verification_chase_email)
      ).and_return(double(deliver_later: nil))

      FurtherEducationPayments::ProviderVerificationChaseEmailJob.new.perform
    end

    it "sends an email only to unverified claims with a provider email last sent over 3 weeks ago " do
      expect(claim_with_provider_email_sent_over_3_weeks_ago.eligibility.reload.provider_verification_email_last_sent_at).to eq Time.now

      expect(ClaimMailer).to(
        have_received(:further_education_payment_provider_verification_chase_email)
          .with(claim_with_provider_email_sent_over_3_weeks_ago)
          .exactly(1).times
      )

      # Make sure no other claims got through
      expect(ClaimMailer).to(
        have_received(:further_education_payment_provider_verification_chase_email)
          .exactly(1).times
      )
    end

    it "creates a note that chaser email was sent" do
      note = claim_with_provider_email_sent_over_3_weeks_ago.reload.notes.order(created_at: :desc).first
      school = claim_with_provider_email_sent_over_3_weeks_ago.school

      expect(note.body).to eq "Verification chaser email sent to #{school.name}"
      expect(note.label).to eq "provider_verification"
      expect(note.created_by_id).to be_nil
    end

    it "does not send a chaser if a provider email was not previously sent" do
      expect(claim_with_no_provider_email_sent.eligibility.reload.provider_verification_email_last_sent_at).to be_nil

      expect(ClaimMailer).to(
        have_received(:further_education_payment_provider_verification_chase_email)
          .with(claim_with_no_provider_email_sent)
          .exactly(0).times
      )
    end

    it "does not send a chaser if it has not been 3 weeks since a provider email was sent" do
      expect(claim_with_provider_email_sent_less_than_3_weeks_ago.eligibility.reload.provider_verification_email_last_sent_at).to eq DateTime.new(2024, 10, 15, 7, 0, 0)

      expect(ClaimMailer).to(
        have_received(:further_education_payment_provider_verification_chase_email)
          .with(claim_with_provider_email_sent_less_than_3_weeks_ago)
          .exactly(0).times
      )
    end

    it "does not sent a chaser for any claims that are verified" do
      expect(claim_with_provider_email_sent_over_3_weeks_ago_verified.eligibility.reload.provider_verification_email_last_sent_at).to eq DateTime.new(2024, 10, 1, 7, 0, 0)

      expect(ClaimMailer).to(
        have_received(:further_education_payment_provider_verification_chase_email)
          .with(claim_with_provider_email_sent_over_3_weeks_ago_verified)
          .exactly(0).times
      )
    end
  end
end
