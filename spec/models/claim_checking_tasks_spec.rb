# frozen_string_literal: true

require "rails_helper"

RSpec.describe ClaimCheckingTasks do
  let(:claim) { build(:claim, policy: MathsAndPhysics) }
  let(:checking_tasks) { ClaimCheckingTasks.new(claim) }

  describe "#applicable_task_names" do
    it "returns the tasks that apply to the claim" do
      expect(checking_tasks.applicable_task_names).to eq %w[qualifications employment]
    end

    it "includes the a task for student loan amount for a StudentLoans claim" do
      student_loan_claim = build(:claim, policy: StudentLoans)
      student_loan_tasks = ClaimCheckingTasks.new(student_loan_claim)

      expect(student_loan_tasks.applicable_task_names).to eq %w[qualifications employment student_loan_amount]
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
