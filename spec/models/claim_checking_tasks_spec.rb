# frozen_string_literal: true

require "rails_helper"

RSpec.describe ClaimCheckingTasks do
  let(:checking_tasks) { described_class.new(claim) }
  let(:claim) { create(:claim, :submitted, :verified, policy:) }
  let(:policy) { Policies::TargetedRetentionIncentivePayments }
  let(:base_tasks) { %w[identity_confirmation qualifications employment census_subjects_taught] }
  let(:ecp_tasks) { base_tasks + %w[induction_confirmation student_loan_plan] }
  let(:targeted_retention_incentive_tasks) { base_tasks + %w[student_loan_plan] }
  let(:tslr_tasks) { base_tasks + %w[student_loan_amount] }
  let(:applicable_tasks) { [] }

  describe "#applicable_task_names" do
    shared_examples :payroll_gender_task do
      it "includes a task for payroll gender when the claim does not have a binary value for it" do
        claim.payroll_gender = :dont_know

        expect(checking_tasks.applicable_task_names).to match_array(applicable_tasks + %w[payroll_gender])
      end

      it "includes a task for payroll gender when a payroll gender task has previously been completed" do
        create(:task, name: "payroll_gender", claim: claim)

        expect(checking_tasks.applicable_task_names).to match_array(applicable_tasks + %w[payroll_gender])
      end
    end

    shared_examples :matching_details_task do
      it "includes a task for matching details when there are claims with matching details" do
        create(:claim, :submitted, policy:, eligibility_attributes: {teacher_reference_number: claim.eligibility.teacher_reference_number})

        expect(checking_tasks.applicable_task_names).to match_array(applicable_tasks + %w[matching_details])
      end
    end

    shared_examples :payroll_details_task do
      it "includes a task for payroll details when the bank details have not been validated" do
        claim.hmrc_bank_validation_succeeded = false

        expect(checking_tasks.applicable_task_names).to match_array(applicable_tasks + %w[payroll_details])
      end
    end

    shared_examples :student_loan_plan_task do
      it "does not include a task for student loan plan when the claim was submitted using SLC data" do
        claim.submitted_using_slc_data = true

        expect(checking_tasks.applicable_task_names).not_to include("student_loan_plan")
      end
    end

    shared_examples :common_tasks do
      it "returns all the tasks that apply to the claim" do
        expect(checking_tasks.applicable_task_names).to match_array(applicable_tasks)
      end
    end

    context "StudentLoans claim" do
      let(:policy) { Policies::StudentLoans }
      let(:applicable_tasks) { tslr_tasks }

      include_examples :common_tasks
      include_examples :payroll_gender_task
      include_examples :matching_details_task
      include_examples :payroll_details_task
    end

    context "EarlyCareerPayments claim" do
      let(:policy) { Policies::EarlyCareerPayments }
      let(:applicable_tasks) { ecp_tasks }

      include_examples :common_tasks
      include_examples :payroll_gender_task
      include_examples :matching_details_task
      include_examples :payroll_details_task
      include_examples :student_loan_plan_task
    end

    context "TargetedRetentionIncentivePayments claim" do
      let(:policy) { Policies::TargetedRetentionIncentivePayments }
      let(:applicable_tasks) { targeted_retention_incentive_tasks }

      include_examples :common_tasks
      include_examples :payroll_gender_task
      include_examples :matching_details_task
      include_examples :payroll_details_task
      include_examples :student_loan_plan_task
    end

    context "FurtherEducationPayments claim" do
      subject { described_class.new(claim) }

      let(:policy) { Policies::FurtherEducationPayments }

      include_examples :student_loan_plan_task

      context "when TRN is provided" do
        before do
          claim.eligibility.update!(teacher_reference_number: "1234567")
        end

        it "includes employment task" do
          expect(subject.applicable_task_names).to include("employment")
        end
      end

      context "when TRN is not included" do
        before do
          claim.eligibility.update!(teacher_reference_number: nil)
        end

        it "excludes employment task" do
          expect(subject.applicable_task_names).not_to include("employment")
        end
      end
    end
  end

  describe "#incomplete_task_names" do
    it "returns an array of the tasks that haven’t been completed on the claim" do
      expect(checking_tasks.incomplete_task_names).to match_array(targeted_retention_incentive_tasks)

      claim.tasks << create(:task, name: "qualifications")
      expect(checking_tasks.incomplete_task_names).to match_array(%w[identity_confirmation employment census_subjects_taught student_loan_plan])

      claim.tasks << create(:task, name: "employment")
      expect(checking_tasks.incomplete_task_names).to match_array(%w[identity_confirmation census_subjects_taught student_loan_plan])
    end
  end

  describe "#passed_automatically_task_names" do
    subject { checking_tasks.passed_automatically_task_names }

    it "returns an array of the tasks that have passed automatically", flaky: true do
      claim.tasks << create(:task, :failed, :automated, name: "identity_confirmation")
      claim.tasks << create(:task, :passed, :automated, name: "qualifications")
      claim.tasks << create(:task, :passed, :automated, name: "employment")
      claim.tasks << create(:task, :passed, :manual, name: "payroll_gender")

      is_expected.to match_array(%w[qualifications employment])
    end
  end

  describe "#all_tasks_passed_automatically?" do
    subject { checking_tasks.all_tasks_passed_automatically? }

    context "when all tasks passed automatically" do
      before do
        targeted_retention_incentive_tasks.each do |task|
          claim.tasks << create(:task, :passed, :automated, name: task)
        end
      end

      it { is_expected.to eq(true) }
    end

    context "when all tasks automatically passed but there is a duplicate claim" do
      before do
        targeted_retention_incentive_tasks.each do |task|
          claim.tasks << create(:task, :passed, :automated, name: task)
        end
      end

      let!(:previous_claim) { create(:claim, :submitted, policy:, eligibility_attributes: {teacher_reference_number: claim.eligibility.teacher_reference_number}) }

      it { is_expected.to eq(false) }
    end

    context "when some tasks passed automatically and at least one passed manually" do
      before do
        claim.tasks << create(:task, :passed, :automated, name: "identity_confirmation")
        claim.tasks << create(:task, :passed, :automated, name: "qualifications")
        claim.tasks << create(:task, :passed, :manual, name: "employment")
      end

      it { is_expected.to eq(false) }
    end

    context "when some tasks failed automatically" do
      before do
        claim.tasks << create(:task, :failed, :automated, name: "identity_confirmation")
        claim.tasks << create(:task, :passed, :automated, name: "qualifications")
        claim.tasks << create(:task, :passed, :automated, name: "employment")
      end

      it { is_expected.to eq(false) }
    end
  end
end
