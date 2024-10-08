module Admin
  class TaskPagination
    include Rails.application.routes.url_helpers

    attr_reader :claim, :current_task_name

    def initialize(claim:, current_task_name:)
      @claim = claim
      @current_task_name = current_task_name
    end

    def next_task_name
      return unless current_task_index.present?

      string = claim_checking_tasks
        .applicable_task_names[current_task_index + 1]

      string || "decision"
    end

    def next_task_path
      if next_task_name == "decision"
        new_admin_claim_decision_path(claim)
      elsif next_task_name.present?
        admin_claim_task_path(claim, name: next_task_name)
      end
    end

    def previous_task_name
      return claim_checking_tasks.applicable_task_names.last unless current_task_index.present?

      previous_index = current_task_index - 1
      (previous_index >= 0) ? claim_checking_tasks.applicable_task_names[current_task_index - 1] : nil
    end

    def previous_task_path
      return unless previous_task_name.present?

      admin_claim_task_path(claim, name: previous_task_name)
    end

    private

    def current_task_index
      claim_checking_tasks
        .applicable_task_names
        .index(current_task_name)
    end

    def claim_checking_tasks
      @claim_checking_tasks ||= ClaimCheckingTasks.new(claim)
    end
  end
end
