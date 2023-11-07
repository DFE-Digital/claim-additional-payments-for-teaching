require "rails_helper"

RSpec.describe Decision, type: :model do
  it "should not permit changes after creation" do
    claim = create(:claim, :submitted)
    user = create(:dfe_signin_user)
    decision = Decision.create!(claim: claim, created_by: user, result: :approved)

    expect { decision.update(created_by: build(:dfe_signin_user)) }.to raise_error(ActiveRecord::ReadOnlyRecord)

    expect(decision.reload.created_by).to eq(user)
  end

  it "validates the decision has a result" do
    expect(build(:decision, result: "approved")).to be_valid
    expect(build(:decision, result: nil)).not_to be_valid
  end

  it "prevents an unapprovable claim from being approved" do
    claim = create(:claim, :ineligible)
    decision = build(:decision, claim: claim, result: "approved")

    expect(decision).not_to be_valid
    expect(decision.errors.messages[:base]).to eq(["This claim cannot be approved"])
  end

  it "prevents an unrejectable claim from being rejected" do
    claim = create(:claim, :held)
    decision = build(:decision, claim: claim, result: "rejected")

    expect(decision).not_to be_valid
    expect(decision.errors.messages[:base]).to eq(["This claim cannot be rejected"])
  end

  it "prevents a decision being marked as undone when a claim cannot have its decision undone" do
    claim = create(:claim, :submitted)
    decision = create(:decision, claim: claim, result: "approved")
    create(:payment, claims: [claim])
    decision.undone = true
    decision.save

    expect(decision).not_to be_valid
    expect(decision.errors.messages[:base]).to eq(["This claim cannot have its decision undone"])
  end

  it "prevents a claim with matching bank details from being approved" do
    personal_details = {
      teacher_reference_number: generate(:teacher_reference_number),
      bank_sort_code: "112233"
    }

    create(:claim, :approved, personal_details.merge(bank_account_number: "12345678"))
    claim_to_approve = create(:claim, :submitted, personal_details.merge(bank_account_number: "99999999"))
    decision = build(:decision, claim: claim_to_approve, result: "approved")

    expect(decision).not_to be_valid
    expect(decision.errors.messages[:base]).to eq(["This claim cannot be approved"])
  end

  describe "#rejected_reasons_hash" do
    subject { decision.rejected_reasons_hash }
    let(:decision) { create(:decision, :rejected, **rejected_reasons) }
    let(:rejected_reasons) do
      {
        rejected_reasons_ineligible_subject: "1",
        rejected_reasons_no_qts_or_qtls: "1"
      }
    end
    let(:expected_hash) do
      {
        reason_ineligible_subject: "1",
        reason_ineligible_year: "0",
        reason_ineligible_school: "0",
        reason_ineligible_qualification: "0",
        reason_no_qts_or_qtls: "1",
        reason_duplicate: "0",
        reason_no_response: "0",
        reason_other: "0"
      }
    end

    it "returns the complete hash of rejected reasons" do
      is_expected.to eq(expected_hash)
    end
  end
end
