require "rails_helper"

RSpec.describe Amendment, type: :model do
  it "is invalid if there are no claim changes" do
    amendment = build(:amendment, claim_changes: {})
    expect(amendment).not_to be_valid

    amendment.claim_changes = {"teacher_reference_number" => ["7654321", "1234567"]}
    expect(amendment).to be_valid
  end

  it "is invalid if the notes are empty" do
    amendment = build(:amendment, notes: "")
    expect(amendment).not_to be_valid

    amendment.notes = "Claimant made a typo"
    expect(amendment).to be_valid
  end
end
