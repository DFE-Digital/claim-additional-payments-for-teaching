class Admin::PayrollGenderTasksController < Admin::TasksController
  def create
    @claim_checking_tasks = ClaimCheckingTasks.new(@claim)
    @task = @claim.tasks.build(check_params)
    @current_task_name = current_task_name
    @claim.attributes = claim_params
    @task_pagination = Admin::TaskPagination.new(claim: @claim, current_task_name:)

    if claim_and_task_saved?
      redirect_to @task_pagination.next_task_path
    else
      @tasks_presenter = @claim.policy::AdminTasksPresenter.new(@claim)
      render @task.name
    end
  end

  private

  def claim_params
    params.require(:claim).permit(:payroll_gender)
  end

  def claim_and_task_saved?
    ActiveRecord::Base.transaction do
      @claim.save!(context: :"payroll-gender-task")
      @task.save!
    end
  rescue ActiveRecord::RecordInvalid
    false
  end

  def current_task_name
    @task.name
  end
end
