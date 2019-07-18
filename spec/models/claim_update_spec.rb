# frozen_string_literal: true

require "rails_helper"

RSpec.describe ClaimUpdate do
  let(:claim_update) { ClaimUpdate.new(claim, params, context) }

  context "with parameters that are valid for the context" do
    let(:claim) { create(:tslr_claim) }
    let(:context) { "bank-details" }
    let(:params) { {bank_sort_code: "123456", bank_account_number: "12345678"} }

    it "updates the claim and returns a truthy value" do
      expect(claim_update.perform).to be_truthy
      expect(claim.reload.bank_sort_code).to eq "123456"
      expect(claim.bank_account_number).to eq "12345678"
    end
  end

  context "with parameters missing for the context" do
    let(:claim) { create(:tslr_claim) }
    let(:context) { "bank-details" }
    let(:params) { {bank_sort_code: nil, bank_account_number: "12345678"} }

    it "doesn't update the claim and returns a falsy value" do
      expect(claim_update.perform).to be_falsy
      expect(claim.errors[:bank_sort_code]).to eq ["Enter a sort code"]
    end
  end

  context "when updating claim that is submittable in the “check-your-answers” context" do
    let(:claim) { create(:tslr_claim, :submittable) }
    let(:context) { "check-your-answers" }
    let(:params) { {} }

    it "transitions the claim to a submitted state and returns a truthy" do
      expect(claim_update.perform).to be_truthy
      expect(claim.reload).to be_submitted
    end

    it "queues a confirmation email to be sent to the claimant" do
      claim_update.perform
      expect(ActionMailer::DeliveryJob).to have_been_enqueued.with("ClaimMailer", "submitted", "deliver_now", claim)
    end
  end

  context "when updating an unsubmittable claim in the “check-your-answers” context" do
    let(:claim) { create(:tslr_claim, :submittable, full_name: nil) }
    let(:context) { "check-your-answers" }
    let(:params) { {} }

    it "returns false and does not queue a confirmation email" do
      expect(claim_update.perform).to be_falsy
      expect(ActionMailer::DeliveryJob).not_to have_been_enqueued
    end
  end
end
