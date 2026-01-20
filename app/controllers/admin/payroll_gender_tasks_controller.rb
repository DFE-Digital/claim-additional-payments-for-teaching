class Admin::PayrollGenderTasksController < Admin::TasksController
  def create
    @claim_checking_tasks = ClaimCheckingTasks.new(@claim)
    @form = Admin::Tasks::PayrollGenderForm.new(form_params.merge(name: "payroll_gender", claim: @claim))
    @task_pagination = Admin::TaskPagination.new(claim: @claim, current_task_name: @form.task.name)

    if @form.save
      redirect_to @task_pagination.next_task_path
    else
      @tasks_presenter = @claim.policy.admin_tasks_presenter(@claim)
      @notes = @claim.notes.by_label("payroll_gender")
      @task_note = Note.new
      render "payroll_gender"
    end
  end

  private

  def form_params
    params.require(:form).permit(:payroll_gender)
  end
end
