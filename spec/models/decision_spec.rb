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
end
