# frozen_string_literal: true

# This models the tasks that need to be performed on a claim as part of the
# claim checking process.
class ClaimCheckingTasks
  TASK_NAMES = %w[qualifications employment].freeze

  attr_reader :claim

  def initialize(claim)
    @claim = claim
  end

  # Returns an Array task names that need to be performed on the claim during
  # claim checking before it should be approved.
  def applicable_task_names
    TASK_NAMES
  end

  # Returns an Array of tasks names that have not been completed on the claim.
  def incomplete_task_names
    applicable_task_names - claim.tasks.map(&:name)
  end
end
