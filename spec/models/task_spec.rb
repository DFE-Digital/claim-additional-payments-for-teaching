require "rails_helper"

RSpec.describe Task, type: :model do
  it "validates that there can only be one task of a particular type per claim" do
    claim = create(:claim)
    first_employment_task = create(:task, name: "employment", claim: claim)
    second_employment_task = build(:task, name: "employment", claim: claim)

    expect(first_employment_task).to be_valid
    expect(second_employment_task).not_to be_valid
  end
end
