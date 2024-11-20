class ClaimAutoApproval
  class AutoApprovalFailed < StandardError; end

  def initialize(claim)
    @claim = claim
  end

  def eligible?
    approvable? && auto_approvable?
  end

  def auto_approve!
    return unless eligible?

    claim.transaction do
      claim.decisions.create!(result: :approved, notes: "Auto-approved")
      claim.notes.create!(
        body: <<~TEXT
          This claim was auto-approved because it passed all automated checks
          (#{passed_automatically_task_names.map(&:humanize).join(", ")})
        TEXT
      )
      if claim.flaggable_for_qa?
        claim.update!(qa_required: true)
        claim.notes.create!(body: "This claim has been marked for a quality assurance review")
      end

      claim.policy.mailer.approved(claim).deliver_later unless claim.awaiting_qa?
    rescue ActiveRecord::RecordInvalid => e
      raise AutoApprovalFailed, e
    end
  end

  private

  attr_reader :claim

  delegate :approvable?, to: :claim
  delegate :all_tasks_passed_automatically?, :applicable_task_names, :passed_automatically_task_names, to: :claim_checking_tasks

  def auto_approvable?
    return true if all_tasks_passed_automatically?
    return false unless (applicable_task_names - passed_automatically_task_names) == ["census_subjects_taught"]

    # We can still auto-approve a claim when the "census_subjects_taught" task is the only
    # applicable one that didn't pass automatically and the outcome is "NO DATA"
    claim.tasks.automated.no_data_census_subjects_taught.exists?
  end

  def claim_checking_tasks
    @claim_checking_tasks ||= ClaimCheckingTasks.new(claim)
  end
end
