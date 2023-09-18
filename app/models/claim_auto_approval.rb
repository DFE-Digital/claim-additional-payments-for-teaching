class ClaimAutoApproval
  class AutoApprovalFailed < StandardError; end

  def initialize(claim)
    @claim = claim
  end

  def eligible?
    approvable? && all_tasks_passed_automatically?
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

      ClaimMailer.approved(claim).deliver_later unless claim.awaiting_qa?

    rescue ActiveRecord::RecordInvalid => e
      raise AutoApprovalFailed, e
    end
  end

  private

  attr_reader :claim

  delegate :approvable?, to: :claim
  delegate :all_tasks_passed_automatically?, :passed_automatically_task_names, to: :claim_checking_tasks

  def claim_checking_tasks
    @claim_checking_tasks ||= ClaimCheckingTasks.new(claim)
  end
end
