# frozen_string_literal: true

# This models the tasks that need to be performed on a claim as part of the
# claim checking process.
class ClaimCheckingTasks
  TASK_NAMES = %w[qualifications employment student_loan_amount].freeze

  attr_reader :claim

  def initialize(claim)
    @claim = claim
  end

  def applicable_task_names
    @applicable_task_names ||= TASK_NAMES.dup.tap do |task_names|
      task_names.delete("student_loan_amount") unless claim.policy == StudentLoans
    end
  end

  # Returns an Array of tasks names that have not been completed on the claim.
  def incomplete_task_names
    applicable_task_names - claim.tasks.map(&:name)
  end
end
