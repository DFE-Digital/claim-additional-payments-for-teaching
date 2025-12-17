module Admin
  class TaskListsController < Admin::BaseAdminController
    before_action :ensure_service_operator

    def index
      @presenter = Admin::TaskListForm.new(task_list_params)

      # TODO respond to CSV
    end

    private

    def task_list_params
      params.permit(
        :policy_name,
        :show_filter_controls,
        :clear_statuses,
        statuses: Hash.new { [] }
      )
    end
  end
end
