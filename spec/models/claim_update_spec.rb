# frozen_string_literal: true

require "rails_helper"

RSpec.describe ClaimUpdate do
  let(:claim_update) { ClaimUpdate.new(claim, params, context) }

  context "with parameters that are valid for the context" do
    let(:claim) { create(:claim, :submittable) }
    let(:context) { "bank-details" }
    let(:params) do
      {
        banking_name: "Jo Bloggs",
        bank_sort_code: "123456",
        bank_account_number: "12345678",
        building_society_roll_number: "1234/12345678",
        has_student_loan: false,
        eligibility_attributes: {had_leadership_position: false},
      }
    end

    it "updates the claim and returns a truthy value" do
      expect(claim_update.perform).to be_truthy
      expect(claim.banking_name).to eq "Jo Bloggs"
      expect(claim.reload.bank_sort_code).to eq "123456"
      expect(claim.bank_account_number).to eq "12345678"
      expect(claim.building_society_roll_number).to eq "1234/12345678"
    end

    it "resets dependent attributes on the claim" do
      claim_update.perform
      expect(claim.student_loan_plan).to eq Claim::NO_STUDENT_LOAN
    end

    it "resets dependent attributes on the eligibility" do
      claim_update.perform
      expect(claim.eligibility.mostly_performed_leadership_duties).to be_nil
    end
  end

  context "with parameters missing for the context" do
    let(:claim) { create(:claim) }
    let(:context) { "bank-details" }
    let(:params) { {bank_sort_code: nil, bank_account_number: "12345678"} }

    it "doesn't update the claim and returns false" do
      expect(claim_update.perform).to eq false
      expect(claim.errors[:bank_sort_code]).to eq ["Enter a sort code"]
    end
  end
end
