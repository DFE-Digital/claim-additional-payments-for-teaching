# frozen_string_literal: true

require "rails_helper"

RSpec.describe ClaimCheckingTasks do
  let(:claim) { build(:claim, :submitted, :verified, policy: MathsAndPhysics) }
  let(:checking_tasks) { ClaimCheckingTasks.new(claim) }

  describe "#applicable_task_names" do
    it "returns the tasks that apply to the claim" do
      expect(checking_tasks.applicable_task_names).to eq %w[qualifications employment]
    end

    it "includes the a task for student loan amount for a StudentLoans claim" do
      student_loan_claim = build(:claim, :submitted, :verified, policy: StudentLoans)
      student_loan_tasks = ClaimCheckingTasks.new(student_loan_claim)

      expect(student_loan_tasks.applicable_task_names).to eq %w[qualifications employment student_loan_amount]
    end

    it "includes the matching details task when there are claims with matching details" do
      create(:claim, :submitted,
        policy: MathsAndPhysics,
        teacher_reference_number: claim.teacher_reference_number)

      expect(checking_tasks.applicable_task_names).to eq %w[qualifications employment matching_details]
    end

    it "includes a task for identity confirmation for a StudentLoans claim where the claimant didn’t complete GOV.UK Verify" do
      unverified_claim = build(:claim, :unverified, policy: StudentLoans)
      unverified_tasks = ClaimCheckingTasks.new(unverified_claim)

      expect(unverified_tasks.applicable_task_names).to eq %w[identity_confirmation qualifications employment student_loan_amount]
    end

    it "includes a task for identity confirmation for a MathsAndPhysics claim where the claimant didn’t complete GOV.UK Verify" do
      unverified_claim = build(:claim, :unverified, policy: MathsAndPhysics)
      unverified_tasks = ClaimCheckingTasks.new(unverified_claim)

      expect(unverified_tasks.applicable_task_names).to eq %w[identity_confirmation qualifications employment]
    end

    it "includes a task for payroll gender when the claim does not have a binary value for it" do
      claim.payroll_gender = :dont_know

      expect(checking_tasks.applicable_task_names).to eq %w[qualifications employment payroll_gender]
    end

    it "includes a task for payroll gender when a payroll gender task has previously been completed" do
      claim.tasks << build(:task, name: "payroll_gender")

      expect(checking_tasks.applicable_task_names).to eq %w[qualifications employment payroll_gender]
    end
  end

  describe "#incomplete_task_names" do
    it "returns an array of the tasks that haven’t been completed on the claim" do
      expect(checking_tasks.incomplete_task_names).to eq %w[qualifications employment]

      claim.tasks << build(:task, name: "qualifications")
      expect(checking_tasks.incomplete_task_names).to eq ["employment"]

      claim.tasks << build(:task, name: "employment")
      expect(checking_tasks.incomplete_task_names).to eq []
    end
  end
end
