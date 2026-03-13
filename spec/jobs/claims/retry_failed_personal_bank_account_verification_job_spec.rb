require "rails_helper"

RSpec.describe Claims::RetryFailedPersonalBankAccountVerificationJob, type: :job do
  context "when the claim is outside the date range" do
    it "doesn't queue a verification job" do
      create(
        :claim,
        created_at: DateTime.new(2026, 3, 1, 9, 0, 0),
        hmrc_bank_validation_succeeded: false
      )

      described_class.perform_now

      expect(Claims::VerifyPersonalBankAccountJob).not_to have_been_enqueued
    end
  end

  context "when the claim is within the date range" do
    context "when the claim has already been successfully validated" do
      it "doesn't queue a verification job" do
        create(
          :claim,
          created_at: DateTime.new(2026, 3, 2, 9, 0, 0),
          hmrc_bank_validation_succeeded: true
        )

        described_class.perform_now

        expect(Claims::VerifyPersonalBankAccountJob).not_to have_been_enqueued
      end
    end

    context "when the claim has not been successfully validated" do
      it "queues a verification job for each claim spaced 5 seconds a part" do
        claim_1 = create(
          :claim,
          created_at: DateTime.new(2026, 3, 2, 9, 0, 0),
          hmrc_bank_validation_succeeded: false,
          reference: "claim_1"
        )

        claim_2 = create(
          :claim,
          created_at: DateTime.new(2026, 3, 2, 9, 0, 5),
          hmrc_bank_validation_succeeded: false,
          reference: "claim_2"
        )

        described_class.perform_now

        expect(Claims::VerifyPersonalBankAccountJob).to(
          have_been_enqueued.with(claim_1)
        )

        expect(Claims::VerifyPersonalBankAccountJob).to(
          have_been_enqueued.with(claim_2)
        )
      end
    end
  end
end
