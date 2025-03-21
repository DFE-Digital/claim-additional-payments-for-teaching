module Tasks
  def self.status(claim:, task_name:)
    task = claim.tasks.detect { |t| t.name == task_name }

    _generic(task)
  end

  def self._generic(task)
    if task.nil?
      status = "Incomplete"
      status_colour = "grey"
    elsif task.passed?
      status = "Passed"
      status_colour = "green"
    elsif task.passed == false
      status = task.reason&.humanize || "Failed"
      status_colour = "red"
    elsif task.claim_verifier_match_all?
      status = "Full match"
      status_colour = "green"
    elsif task.claim_verifier_match_any?
      status = "Partial match"
      status_colour = "yellow"
    elsif task.claim_verifier_match_none?
      status = "No match"
      status_colour = "red"
    elsif task.claim_verifier_match.nil? && %w[census_subjects_taught employment induction_confirmation student_loan_amount student_loan_plan].include?(task.name)
      status = "No data"
      status_colour = "red"
    end

    [status, status_colour]
  end
end
