require "rails_helper"

RSpec.describe FurtherEducationPayments::ProviderVerificationChaseEmailJob do
  let(:now) { DateTime.new(2024, 10, 22, 8, 0, 0) }

  around do |example|
    travel_to now do
      example.run
    end
  end

  describe "#perform" do
    context "with unverified claim with email sent over 2 weeks ago" do
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

      before do
        allow(ClaimMailer).to(
          receive(:further_education_payment_provider_verification_chase_email)
        ).and_return(double(deliver_later: nil))

        FurtherEducationPayments::ProviderVerificationChaseEmailJob.new.perform
      end

      it "sends an email" do
        expect(claim_with_provider_email_sent_over_2_weeks_ago.eligibility.reload.provider_verification_email_last_sent_at).to eq Time.now

        expect(ClaimMailer).to(
          have_received(:further_education_payment_provider_verification_chase_email)
            .with(claim_with_provider_email_sent_over_2_weeks_ago)
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
    end

    context "provider email was not previously sent" do
      let!(:claim_with_no_provider_email_sent) {
        create(:claim,
          :submitted,
          policy: Policies::FurtherEducationPayments,
          eligibility: build(
            :further_education_payments_eligibility,
            :not_verified
          ))
      }

      before do
        allow(ClaimMailer).to(
          receive(:further_education_payment_provider_verification_chase_email)
        ).and_return(double(deliver_later: nil))

        FurtherEducationPayments::ProviderVerificationChaseEmailJob.new.perform
      end

      it "does not send a chaser" do
        expect(claim_with_no_provider_email_sent.eligibility.reload.provider_verification_email_last_sent_at).to be_nil
        expect(claim_with_no_provider_email_sent.eligibility.reload.provider_verification_chase_email_last_sent_at).to be_nil

        expect(ClaimMailer).to(
          have_received(:further_education_payment_provider_verification_chase_email)
            .with(claim_with_no_provider_email_sent)
            .exactly(0).times
        )
      end
    end

    context "not been 2 weeks since a provider email was sent" do
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

      before do
        allow(ClaimMailer).to(
          receive(:further_education_payment_provider_verification_chase_email)
        ).and_return(double(deliver_later: nil))

        FurtherEducationPayments::ProviderVerificationChaseEmailJob.new.perform
      end

      it "does not send a chaser" do
        expect(claim_with_provider_email_sent_less_than_2_weeks_ago.eligibility.reload.provider_verification_chase_email_last_sent_at).to be_nil

        expect(ClaimMailer).to(
          have_received(:further_education_payment_provider_verification_chase_email)
            .with(claim_with_provider_email_sent_less_than_2_weeks_ago)
            .exactly(0).times
        )
      end
    end

    context "when claim is verified" do
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

      before do
        allow(ClaimMailer).to(
          receive(:further_education_payment_provider_verification_chase_email)
        ).and_return(double(deliver_later: nil))

        FurtherEducationPayments::ProviderVerificationChaseEmailJob.new.perform
      end

      it "does not sent a chaser" do
        expect(claim_with_provider_email_sent_over_2_weeks_ago_verified.eligibility.reload.provider_verification_chase_email_last_sent_at).to be_nil

        expect(ClaimMailer).to(
          have_received(:further_education_payment_provider_verification_chase_email)
            .with(claim_with_provider_email_sent_over_2_weeks_ago_verified)
            .exactly(0).times
        )
      end
    end

    context "first chaser already sent" do
      let!(:claim_with_provider_chase_email_already_sent) {
        create(:claim,
          :submitted,
          policy: Policies::FurtherEducationPayments,
          eligibility: build(
            :further_education_payments_eligibility,
            :not_verified,
            provider_verification_email_last_sent_at: DateTime.new(2024, 9, 22, 8, 0, 0),
            provider_verification_email_count: 2
          ))
      }

      before do
        allow(ClaimMailer).to(
          receive(:further_education_payment_provider_verification_chase_email)
        ).and_return(double(deliver_later: nil))

        FurtherEducationPayments::ProviderVerificationChaseEmailJob.new.perform
      end

      it "sends chaser email" do
        expect(claim_with_provider_chase_email_already_sent.eligibility.reload.provider_verification_email_last_sent_at).to be_within(10.seconds).of(now)

        expect(ClaimMailer).to(
          have_received(:further_education_payment_provider_verification_chase_email)
            .with(claim_with_provider_chase_email_already_sent)
            .exactly(1).times
        )
      end
    end

    context "second chaser already sent" do
      let!(:claim_with_provider_chase_email_already_sent) {
        create(:claim,
          :submitted,
          policy: Policies::FurtherEducationPayments,
          eligibility: build(
            :further_education_payments_eligibility,
            :not_verified,
            provider_verification_email_last_sent_at: DateTime.new(2024, 9, 22, 8, 0, 0),
            provider_verification_email_count: 3
          ))
      }

      before do
        allow(ClaimMailer).to(
          receive(:further_education_payment_provider_verification_chase_email)
        ).and_return(double(deliver_later: nil))

        FurtherEducationPayments::ProviderVerificationChaseEmailJob.new.perform
      end

      it "does not send a chaser email" do
        expect(claim_with_provider_chase_email_already_sent.eligibility.reload.provider_verification_email_last_sent_at).to eq DateTime.new(2024, 9, 22, 8, 0, 0)

        expect(ClaimMailer).to(
          have_received(:further_education_payment_provider_verification_chase_email)
            .with(claim_with_provider_chase_email_already_sent)
            .exactly(0).times
        )
      end
    end

    context "rejected claim" do
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

      before do
        allow(ClaimMailer).to(
          receive(:further_education_payment_provider_verification_chase_email)
        ).and_return(double(deliver_later: nil))

        FurtherEducationPayments::ProviderVerificationChaseEmailJob.new.perform
      end

      it "does not send a chaser email" do
        expect(claim_rejected_after_provider_verification_was_sent.eligibility.reload.provider_verification_chase_email_last_sent_at).to be_nil

        expect(ClaimMailer).to(
          have_received(:further_education_payment_provider_verification_chase_email)
            .with(claim_rejected_after_provider_verification_was_sent)
            .exactly(0).times
        )
      end
    end

    context "claim on hold" do
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

      it "does not send a chaser email" do
        expect(claim_held_after_provider_verification_was_sent.eligibility.reload.provider_verification_chase_email_last_sent_at).to be_nil

        expect(ClaimMailer).to(
          have_received(:further_education_payment_provider_verification_chase_email)
            .with(claim_held_after_provider_verification_was_sent)
            .exactly(0).times
        )
      end
    end
  end
end
