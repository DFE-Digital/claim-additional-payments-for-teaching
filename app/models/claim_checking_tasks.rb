# frozen_string_literal: true

# This models the tasks that need to be performed on a claim as part of the
# claim checking process.
class ClaimCheckingTasks
  attr_reader :claim

  def initialize(claim)
    @claim = claim
  end

  def applicable_task_names
    @applicable_task_names ||= Task::NAMES.dup.tap do |task_names|
      task_names.delete("student_loan_amount") unless claim.policy == StudentLoans
      task_names.delete("matching_details") unless matching_claims.exists?
      task_names.delete("payroll_gender") unless claim.payroll_gender_missing? || task_names_for_claim.include?("payroll_gender")
    end
  end

  # Returns an Array of tasks names that have not been completed on the claim.
  def incomplete_task_names
    applicable_task_names - task_names_for_claim
  end

  private

  def task_names_for_claim
    claim.tasks.map(&:name)
  end

  def matching_claims
    @matching_claims ||= Claim::MatchingAttributeFinder.new(claim).matching_claims
  end
end
