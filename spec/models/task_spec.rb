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

  describe "scopes" do
    describe ".passed_automatically" do
      subject { described_class.passed_automatically }

      let!(:task_failed_manually) { create(:task, :manual, :failed) }
      let!(:task_passed_manually) { create(:task, :manual, :passed) }
      let!(:task_failed_automatically) { create(:task, :automated, :failed) }
      let!(:task_passed_automatically) { create(:task, :automated, :passed) }
      let!(:another_task_passed_automatically) { create(:task, :automated, :passed) }

      it "returns taks that passed automatically" do
        is_expected.to match_array([task_passed_automatically, another_task_passed_automatically])
      end
    end

    describe ".no_data_census_subjects_taught" do
      subject { described_class.no_data_census_subjects_taught }

      let!(:employment_task_failed_automatically_no_data) { create(:task, :automated, :failed, claim_verifier_match: nil, name: "employment") }

      let!(:census_task_failed_automatically_no_data) { create(:task, :automated, :failed, claim_verifier_match: nil, name: "census_subjects_taught") }
      let!(:another_census_task_failed_automatically_no_data) { create(:task, :automated, :failed, claim_verifier_match: nil, name: "census_subjects_taught") }

      let!(:census_task_failed_automatically_no_match) { create(:task, :automated, :failed, claim_verifier_match: :none, name: "census_subjects_taught") }
      let!(:census_task_passed_automatically_any_match) { create(:task, :automated, :passed, claim_verifier_match: :any, name: "census_subjects_taught") }

      it "returns census subjects taught tasks that didn't pass because the outcome was NO DATA" do
        is_expected.to match_array([census_task_failed_automatically_no_data, another_census_task_failed_automatically_no_data])
      end
    end
  end

  describe "#employment_task_available?" do
    subject { task.employment_task_available? }

    let(:task) { build(:task, claim: claim) }
    let(:claim) { create(:claim, :submitted, policy:) }

    context "for claims with EarlyYearsPayments policy" do
      let(:policy) { Policies::EarlyYearsPayments }

      context "when the task is available" do
        let(:claim) { create(:claim, :submitted, policy:, eligibility_attributes: {start_date: 1.year.ago}) }

        it { is_expected.to be true }
      end

      context "when the task is not yet available" do
        let(:claim) { create(:claim, :submitted, policy:, eligibility_attributes: {start_date: 1.day.ago}) }

        it { is_expected.to be false }
      end
    end

    context "for claims with other policies" do
      (Policies.all - [Policies::EarlyYearsPayments]).each do |policy|
        context policy do
          let(:policy) { policy }

          it { is_expected.to be true }
        end
      end
    end
  end
end
