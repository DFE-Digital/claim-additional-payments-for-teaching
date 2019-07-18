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

  describe "setting/resetting current_school based on the answer to employment_status" do
    context "when the update sets the employment_status to :claim_school" do
      let(:claim) { create(:tslr_claim, claim_school: schools(:penistone_grammar_school)) }
      let(:context) { "still-teaching" }
      let(:params) { {employment_status: "claim_school"} }

      it "automatically sets current_school to match the claim_school" do
        expect(claim_update.perform).to be_truthy
        expect(claim.reload.employment_status).to eq "claim_school"
        expect(claim.current_school).to eq schools(:penistone_grammar_school)
      end
    end

    context "when the update changes employment_status to :different_school" do
      let(:claim) { create(:tslr_claim, claim_school: schools(:penistone_grammar_school), employment_status: :claim_school, current_school: schools(:penistone_grammar_school)) }
      let(:context) { "still-teaching" }
      let(:params) { {employment_status: "different_school"} }

      it "resets the inferrred current_school to nil" do
        expect(claim_update.perform).to be_truthy
        expect(claim.reload.employment_status).to eq "different_school"
        expect(claim.current_school).to be_nil
      end
    end

    context "when the update does not actually change the employment_status" do
      let(:claim) { create(:tslr_claim, claim_school: schools(:penistone_grammar_school), employment_status: :different_school, current_school: schools(:hampstead_school)) }
      let(:context) { "still-teaching" }
      let(:params) { {employment_status: claim.employment_status} }

      it "does not reset the current_school" do
        expect(claim_update.perform).to be_truthy
        expect(claim.reload.employment_status).to eq "different_school"
        expect(claim.current_school).to eq schools(:hampstead_school)
      end
    end
  end
end
