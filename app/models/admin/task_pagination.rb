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

      claim_checking_tasks
        .pageable_tasks[current_task_index + 1]
    end

    def next_task_path
      if next_task_name == "qa_decision"
        if claim.qa_completed?
          admin_claim_decisions_path(claim, qa: true)
        else
          new_admin_claim_decision_path(claim, qa: true)
        end
      elsif next_task_name == "decision"
        if claim.decisions.exists?
          admin_claim_decisions_path(claim)
        else
          new_admin_claim_decision_path(claim)
        end
      elsif next_task_name.present?
        admin_claim_task_path(claim, name: next_task_name)
      end
    end

    def previous_task_name
      return claim_checking_tasks.pageable_tasks.last unless current_task_index.present?

      previous_index = current_task_index - 1
      (previous_index >= 0) ? claim_checking_tasks.pageable_tasks[current_task_index - 1] : nil
    end

    def previous_task_path
      return unless previous_task_name.present?

      case previous_task_name
      when "decision"
        admin_claim_decisions_path(claim)
      else
        admin_claim_task_path(claim, name: previous_task_name)
      end
    end

    private

    def current_task_index
      claim_checking_tasks
        .pageable_tasks
        .index(current_task_name)
    end

    def claim_checking_tasks
      @claim_checking_tasks ||= ClaimCheckingTasks.new(claim)
    end
  end
end
