class Admin::PayrollGenderTasksController < Admin::TasksController
  def create
    @claim_checking_tasks = ClaimCheckingTasks.new(@claim)
    @task = @claim.tasks.build(check_params)
    @claim.attributes = claim_params

    if claim_and_task_saved?
      redirect_to next_task_path
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
end
