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
      params.permit(
        :policy_name,
        :show_filter_controls,
        :clear_statuses,
        statuses: Hash.new { [] }
      )
    end
  end
end
