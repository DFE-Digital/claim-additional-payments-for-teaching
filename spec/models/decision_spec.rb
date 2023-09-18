require "rails_helper"

RSpec.describe Decision, type: :model do
  let(:user) { create(:dfe_signin_user) }

  describe "associations" do
    it { is_expected.to belong_to(:claim) }
    it { is_expected.to belong_to(:created_by).class_name("DfeSignIn::User").optional(true) }
  end

  it "should not permit changes after creation" do
    claim = create(:claim, :submitted)
    decision = Decision.create!(claim: claim, created_by: user, result: :approved)

    expect { decision.update(created_by: user) }.to raise_error(ActiveRecord::ReadOnlyRecord)

    expect(decision.reload.created_by).to eq(user)
  end

  it "validates the decision has a result" do
    expect(build(:decision, result: "approved", created_by: user)).to be_valid
    expect(build(:decision, result: nil, created_by: user)).not_to be_valid
  end

  it "validates the decision has notes when it's automated" do
    expect(build(:decision, :automated, result: "approved", notes: "Auto-approved")).to be_valid
    expect(build(:decision, :automated, result: "approved", notes: nil)).not_to be_valid
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

  it "returns the number of days between the claim being submitted and the claim being decisioned" do
    claim = create(:claim, :submitted, submitted_at: 12.days.ago)
    decision = build(:decision, claim: claim, created_at: DateTime.now)

    expect(decision.number_of_days_since_claim_submitted).to eq(12)
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
