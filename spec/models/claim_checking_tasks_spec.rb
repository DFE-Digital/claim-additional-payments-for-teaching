# frozen_string_literal: true

require "rails_helper"

RSpec.describe ClaimCheckingTasks do
  let(:claim) { create(:claim, :submitted, :verified, policy: Policies::StudentLoans) }
  let(:checking_tasks) { ClaimCheckingTasks.new(claim) }

  describe "#applicable_task_names" do
    it "includes a task for student loan amount for a StudentLoans claim" do
      expect(checking_tasks.applicable_task_names).to eq %w[identity_confirmation qualifications census_subjects_taught employment student_loan_amount]
    end

    it "includes tasks for induction and school workforce census check for a EarlyCareerPayments claim" do
      ecp_claim = create(:claim, :submitted, :verified, policy: Policies::EarlyCareerPayments)
      ecp_tasks = ClaimCheckingTasks.new(ecp_claim)

      expect(ecp_tasks.applicable_task_names).to eq %w[identity_confirmation qualifications induction_confirmation census_subjects_taught employment]
    end

    it "includes the matching details task when there are claims with matching details" do
      create(:claim, :submitted,
        policy: Policies::StudentLoans,
        teacher_reference_number: claim.teacher_reference_number)

      expect(checking_tasks.applicable_task_names).to eq %w[identity_confirmation qualifications census_subjects_taught employment student_loan_amount matching_details]
    end

    it "includes a task for payroll gender when the claim does not have a binary value for it" do
      claim.payroll_gender = :dont_know

      expect(checking_tasks.applicable_task_names).to eq %w[identity_confirmation qualifications census_subjects_taught employment student_loan_amount payroll_gender]
    end

    it "includes a task for payroll gender when a payroll gender task has previously been completed" do
      claim.tasks << create(:task, name: "payroll_gender")

      expect(checking_tasks.applicable_task_names).to eq %w[identity_confirmation qualifications census_subjects_taught employment student_loan_amount payroll_gender]
    end

    it "includes a task for payroll details when the bank details have not been validated" do
      claim.hmrc_bank_validation_succeeded = false
      expect(checking_tasks.applicable_task_names).to eq %w[identity_confirmation qualifications census_subjects_taught employment student_loan_amount payroll_details]
    end
  end

  describe "#incomplete_task_names" do
    it "returns an array of the tasks that haven’t been completed on the claim" do
      expect(checking_tasks.incomplete_task_names).to eq %w[identity_confirmation qualifications census_subjects_taught employment student_loan_amount]

      claim.tasks << create(:task, name: "qualifications")
      expect(checking_tasks.incomplete_task_names).to eq %w[identity_confirmation census_subjects_taught employment student_loan_amount]

      claim.tasks << create(:task, name: "employment")
      expect(checking_tasks.incomplete_task_names).to eq %w[identity_confirmation census_subjects_taught student_loan_amount]
    end
  end

  describe "#passed_automatically_task_names" do
    subject { checking_tasks.passed_automatically_task_names }

    it "returns an array of the tasks that have passed automatically", flaky: true do
      claim.tasks << create(:task, :failed, :automated, name: "identity_confirmation")
      claim.tasks << create(:task, :passed, :automated, name: "qualifications")
      claim.tasks << create(:task, :passed, :automated, name: "employment")
      claim.tasks << create(:task, :passed, :manual, name: "payroll_gender")

      is_expected.to eq %w[qualifications employment]
    end
  end

  describe "#all_tasks_passed_automatically?" do
    subject { checking_tasks.all_tasks_passed_automatically? }

    context "when all tasks passed automatically" do
      before do
        claim.tasks << create(:task, :passed, :automated, name: "identity_confirmation")
        claim.tasks << create(:task, :passed, :automated, name: "qualifications")
        claim.tasks << create(:task, :passed, :automated, name: "census_subjects_taught")
        claim.tasks << create(:task, :passed, :automated, name: "employment")
        claim.tasks << create(:task, :passed, :automated, name: "student_loan_amount")
      end

      it { is_expected.to eq(true) }
    end

    context "when all tasks automatically passed but there is a duplicate claim" do
      before do
        claim.tasks << create(:task, :passed, :automated, name: "identity_confirmation")
        claim.tasks << create(:task, :passed, :automated, name: "qualifications")
        claim.tasks << create(:task, :passed, :automated, name: "employment")
      end

      let!(:previous_claim) { create(:claim, :submitted, teacher_reference_number: claim.teacher_reference_number) }

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
