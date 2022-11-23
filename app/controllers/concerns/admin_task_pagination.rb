module AdminTaskPagination
  def previous_task_name
    return @claim_checking_tasks.applicable_task_names.last unless current_task_index.present?

    previous_index = current_task_index - 1
    previous_index >= 0 ? @claim_checking_tasks.applicable_task_names[current_task_index - 1] : nil
  end

  def next_task_name
    return unless current_task_index.present?
    @claim_checking_tasks.applicable_task_names[current_task_index + 1]
  end

  def current_task_index
    @claim_checking_tasks.applicable_task_names.index(current_task_name)
  end

  def previous_task_path
    return unless previous_task_name.present?
    admin_claim_task_path(@claim, name: previous_task_name)
  end

  def next_task_path
    if next_task_name.present?
      admin_claim_task_path(@claim, name: next_task_name)
    else
      new_admin_claim_decision_path(@claim)
    end
  end

  def set_pagination
    @previous_task_name = previous_task_name
    @previous_task_path = previous_task_path
    @next_task_name = next_task_name
    @next_task_name ||= "decision" unless current_task_name == "decision"
    @next_task_path = next_task_path
  end
end
