class Admin::TasksController < Admin::BaseAdminController
  before_action :ensure_service_operator
  before_action :load_claim
  before_action :ensure_task_has_not_already_been_completed, only: [:create]
  before_action :load_matching_claims, only: [:show], if: -> { current_task_name == "matching_details" }

  def index
    @claim_checking_tasks = ClaimCheckingTasks.new(@claim)
  end

  def show
    @tasks_presenter = @claim.policy::AdminTasksPresenter.new(@claim)
    @task = @claim.tasks.find_or_initialize_by(name: current_task_name)
    render current_task_name
  end

  def create
    @claim_checking_tasks = ClaimCheckingTasks.new(@claim)
    @task = @claim.tasks.build(check_params)
    if @task.save
      redirect_to next_task_path
    else
      @tasks_presenter = @claim.policy::AdminTasksPresenter.new(@claim)
      render current_task_name
    end
  end

  private

  def load_claim
    @claim = Claim.includes(:tasks).find(params[:claim_id])
  end

  def ensure_task_has_not_already_been_completed
    if @claim.tasks.find_by(name: current_task_name)
      redirect_to admin_claim_task_path(@claim, name: current_task_name), alert: "This task has already been completed"
    end
  end

  def current_task_name
    params[:name]
  end

  def next_task_name
    current_task_index = @claim_checking_tasks.applicable_task_names.index(current_task_name)
    @claim_checking_tasks.applicable_task_names[current_task_index + 1]
  end

  def next_task_path
    if next_task_name.present?
      admin_claim_task_path(@claim, name: next_task_name)
    else
      new_admin_claim_decision_path(@claim)
    end
  end

  def check_params
    params.require(:task)
      .permit(:passed)
      .merge(name: current_task_name,
        created_by: admin_user,
        manual: true)
  end

  def load_matching_claims
    @matching_claims = Claim::MatchingAttributeFinder.new(@claim).matching_claims
  end
end
