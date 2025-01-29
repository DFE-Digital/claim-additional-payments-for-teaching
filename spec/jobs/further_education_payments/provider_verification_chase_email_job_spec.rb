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
          :not_verified
        ))
    }

    let!(:claim_with_provider_email_sent_over_2_weeks_ago) {
      create(:claim,
        :submitted,
        policy: Policies::FurtherEducationPayments,
        eligibility: build(
          :further_education_payments_eligibility,
          :not_verified,
          provider_verification_email_last_sent_at: DateTime.new(2024, 10, 8, 7, 0, 0),
          provider_verification_email_count: 1
        ))
    }

    let!(:claim_with_provider_email_sent_less_than_2_weeks_ago) {
      create(:claim,
        :submitted,
        policy: Policies::FurtherEducationPayments,
        eligibility: build(
          :further_education_payments_eligibility,
          :not_verified,
          provider_verification_email_last_sent_at: DateTime.new(2024, 10, 15, 7, 0, 0),
          provider_verification_email_count: 1
        ))
    }

    let!(:claim_with_provider_email_sent_over_2_weeks_ago_verified) {
      create(:claim,
        :submitted,
        policy: Policies::FurtherEducationPayments,
        eligibility: build(
          :further_education_payments_eligibility,
          :eligible,
          provider_verification_email_last_sent_at: DateTime.new(2024, 10, 8, 7, 0, 0),
          provider_verification_email_count: 1
        ))
    }

    let!(:claim_with_provider_chase_email_already_sent) {
      create(:claim,
        :submitted,
        policy: Policies::FurtherEducationPayments,
        eligibility: build(
          :further_education_payments_eligibility,
          :eligible,
          provider_verification_email_last_sent_at: DateTime.new(2024, 9, 22, 8, 0, 0),
          provider_verification_email_count: 2
        ))
    }

    let!(:claim_rejected_after_provider_verification_was_sent) {
      create(:claim,
        :rejected,
        policy: Policies::FurtherEducationPayments,
        eligibility: build(
          :further_education_payments_eligibility,
          :eligible,
          provider_verification_email_last_sent_at: DateTime.new(2024, 10, 8, 7, 0, 0),
          provider_verification_email_count: 1
        ))
    }

    let!(:claim_held_after_provider_verification_was_sent) {
      create(:claim,
        :submitted,
        :held,
        policy: Policies::FurtherEducationPayments,
        eligibility: build(
          :further_education_payments_eligibility,
          :not_verified,
          provider_verification_email_last_sent_at: DateTime.new(2024, 10, 8, 7, 0, 0),
          provider_verification_email_count: 1
        ))
    }

    before do
      allow(ClaimMailer).to(
        receive(:further_education_payment_provider_verification_chase_email)
      ).and_return(double(deliver_later: nil))

      FurtherEducationPayments::ProviderVerificationChaseEmailJob.new.perform
    end

    it "sends an email only to unverified claims with a provider email last sent over 2 weeks ago " do
      expect(claim_with_provider_email_sent_over_2_weeks_ago.eligibility.reload.provider_verification_email_last_sent_at).to eq Time.now

      expect(ClaimMailer).to(
        have_received(:further_education_payment_provider_verification_chase_email)
          .with(claim_with_provider_email_sent_over_2_weeks_ago)
          .exactly(1).times
      )

      # Make sure no other claims got through
      expect(ClaimMailer).to(
        have_received(:further_education_payment_provider_verification_chase_email)
          .exactly(1).times
      )
    end

    it "creates a note that chaser email was sent" do
      note = claim_with_provider_email_sent_over_2_weeks_ago.reload.notes.order(created_at: :desc).first
      school = claim_with_provider_email_sent_over_2_weeks_ago.school

      expect(note.body).to eq "Verification chaser email sent to #{school.name}"
      expect(note.label).to eq "provider_verification"
      expect(note.created_by_id).to be_nil
    end

    it "does not send a chaser if a provider email was not previously sent" do
      expect(claim_with_no_provider_email_sent.eligibility.reload.provider_verification_email_last_sent_at).to be_nil
      expect(claim_with_no_provider_email_sent.eligibility.reload.provider_verification_chase_email_last_sent_at).to be_nil

      expect(ClaimMailer).to(
        have_received(:further_education_payment_provider_verification_chase_email)
          .with(claim_with_no_provider_email_sent)
          .exactly(0).times
      )
    end

    it "does not send a chaser if it has not been 2 weeks since a provider email was sent" do
      expect(claim_with_provider_email_sent_less_than_2_weeks_ago.eligibility.reload.provider_verification_chase_email_last_sent_at).to be_nil

      expect(ClaimMailer).to(
        have_received(:further_education_payment_provider_verification_chase_email)
          .with(claim_with_provider_email_sent_less_than_2_weeks_ago)
          .exactly(0).times
      )
    end

    it "does not sent a chaser for any claims that are verified" do
      expect(claim_with_provider_email_sent_over_2_weeks_ago_verified.eligibility.reload.provider_verification_chase_email_last_sent_at).to be_nil

      expect(ClaimMailer).to(
        have_received(:further_education_payment_provider_verification_chase_email)
          .with(claim_with_provider_email_sent_over_2_weeks_ago_verified)
          .exactly(0).times
      )
    end

    it "does not send a chaser email if one has been sent before" do
      expect(claim_with_provider_chase_email_already_sent.eligibility.reload.provider_verification_email_last_sent_at).to eq DateTime.new(2024, 9, 22, 8, 0, 0)

      expect(ClaimMailer).to(
        have_received(:further_education_payment_provider_verification_chase_email)
          .with(claim_with_provider_chase_email_already_sent)
          .exactly(0).times
      )
    end

    it "does not send a chaser email if the claim has been rejected" do
      expect(claim_rejected_after_provider_verification_was_sent.eligibility.reload.provider_verification_chase_email_last_sent_at).to be_nil

      expect(ClaimMailer).to(
        have_received(:further_education_payment_provider_verification_chase_email)
          .with(claim_rejected_after_provider_verification_was_sent)
          .exactly(0).times
      )
    end

    it "does not send a chaser email if the claimis on hold" do
      expect(claim_held_after_provider_verification_was_sent.eligibility.reload.provider_verification_chase_email_last_sent_at).to be_nil

      expect(ClaimMailer).to(
        have_received(:further_education_payment_provider_verification_chase_email)
          .with(claim_held_after_provider_verification_was_sent)
          .exactly(0).times
      )
    end
  end
end
