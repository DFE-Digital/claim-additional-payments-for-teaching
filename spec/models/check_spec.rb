require "rails_helper"

RSpec.describe Check, type: :model do
  it "validates that there can only be one check of a particular type per claim" do
    claim = create(:claim)
    first_employment_check = create(:check, name: "employment", claim: claim)
    second_employment_check = build(:check, name: "employment", claim: claim)

    expect(first_employment_check).to be_valid
    expect(second_employment_check).not_to be_valid
  end
end
