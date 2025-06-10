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
    claim.task_list
  end

  def locale_key_for_task_name(name)
    r = applicable_task_objects.find do |object|
      object.name == name
    end

    if r.nil?
      name
    else
      r.locale_key
    end
  end

  # FIXME RL: total mess, sort this out
  def applicable_task_objects
    applicable_task_names.map do |name|
      if claim.policy == Policies::FurtherEducationPayments
        if FeatureFlag.disabled?(:alternative_idv) && name == "one_login_identity"
          OpenStruct.new(name:, locale_key: "identity_confirmation")
        elsif FeatureFlag.enabled?(:alternative_idv) && name == "provider_verification"
          OpenStruct.new(name:, locale_key: "eligibility_check")
        else
          OpenStruct.new(name:, locale_key: name)
        end
      else
        OpenStruct.new(name:, locale_key: name)
      end
    end
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
