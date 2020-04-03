require "rails_helper"

RSpec.describe Task, type: :model do
  it "validates that there can only be one task of a particular type per claim" do
    claim = create(:claim)
    first_employment_task = create(:task, name: "employment", claim: claim)
    second_employment_task = build(:task, name: "employment", claim: claim)

    expect(first_employment_task).to be_valid
    expect(second_employment_task).not_to be_valid
  end

  it "validates name is from the defined list of tasks" do
    task = build(:task)

    Task::NAMES.each do |name|
      task.name = name
      expect(task).to be_valid
    end

    task.name = "bogus_task"
    expect(task).not_to be_valid
    expect(task.errors.messages[:name]).to include("name not recognised")
  end
end
