# frozen_string_literal: true

# This models the tasks that need to be performed on a claim as part of the
# claim checking process.
class ClaimCheckingTasks
  attr_reader :claim

  def self.formatted_task_name(task_name)
    case task_name
    when "qa_decision"
      "QA decision"
    else
      I18n.t(:name, scope: [:admin, :tasks, task_name], default: task_name.humanize)
    end
  end

  def initialize(claim)
    @claim = claim
  end

  delegate :policy, to: :claim

  def applicable_task_names
    policy::ClaimCheckingTasks
      .new(claim)
      .applicable_task_names
  end

  def pageable_tasks
    array = applicable_task_names
    array << "decision"
    array << "qa_decision" if claim.qa_required?

    array
  end

  # Returns an Array of tasks names that have not been completed on the claim.
  def incomplete_task_names
    applicable_task_names - task_names_for_claim
  end

  def passed_automatically_task_names
    claim.tasks.passed_automatically.pluck(:name)
  end

  def all_tasks_passed_automatically?
    (applicable_task_names - passed_automatically_task_names).empty?
  end

  private

  def task_names_for_claim
    claim.tasks.pluck(:name)
  end
end
