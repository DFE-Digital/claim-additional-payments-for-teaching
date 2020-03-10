class Admin::TasksController < Admin::BaseAdminController
  before_action :ensure_service_operator
  before_action :load_claim

  TASKS_SEQUENCE = %w[qualifications employment]

  def index
  end

  def show
    @tasks_presenter = @claim.policy::AdminTasksPresenter.new(@claim)
    @task = @claim.tasks.find_by(name: current_task)
    render current_task
  end

  def create
    @claim.tasks.create!(name: current_task, created_by: admin_user)
    redirect_to next_task_path
  rescue ActiveRecord::RecordInvalid
    redirect_to admin_claim_task_path(@claim, name: current_task), alert: "This check has already been completed"
  end

  private

  def load_claim
    @claim = Claim.includes(:tasks).find(params[:claim_id])
  end

  def current_task
    params[:name]
  end

  def next_task_name
    TASKS_SEQUENCE[TASKS_SEQUENCE.index(current_task) + 1]
  end

  def next_task_path
    if next_task_name.present?
      admin_claim_task_path(@claim, name: next_task_name)
    else
      new_admin_claim_decision_path(@claim)
    end
  end
end
