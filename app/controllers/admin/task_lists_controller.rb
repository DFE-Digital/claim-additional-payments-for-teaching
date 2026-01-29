module Admin
  class TaskListsController < Admin::BaseAdminController
    before_action :ensure_service_operator

    def index
      @presenter = Admin::TaskListForm.new(task_list_params)

      respond_to do |format|
        format.html

        format.csv do
          send_data(
            @presenter.to_csv,
            filename: "task-list-#{Time.zone.now.strftime("%Y%m%d%H%M%S")}.csv"
          )
        end
      end
    end

    private

    def task_list_params
      params.fetch(Admin::TaskListForm.model_name.param_key, {}).permit(
        :policy_name,
        :show_filter_controls,
        :clear_statuses,
        :assignee_id,
        statuses: Hash.new { [] }
      )
    end

    def store_requested_admin_path?
      false
    end
  end
end
