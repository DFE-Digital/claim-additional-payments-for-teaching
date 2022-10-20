class Admin::TasksController < Admin::BaseAdminController
  include AdminTaskPagination

  before_action :ensure_service_operator
  before_action :load_claim
  before_action :ensure_task_has_not_already_been_completed, only: [:create]
  before_action :load_matching_claims, only: [:show], if: -> { params[:name] == "matching_details" }

  def index
    @claim_checking_tasks = ClaimCheckingTasks.new(@claim)
    @has_matching_claims = Claim::MatchingAttributeFinder.new(@claim).matching_claims.exists?
  end

  def show
    @claim_checking_tasks = ClaimCheckingTasks.new(@claim)
    @tasks_presenter = @claim.policy::AdminTasksPresenter.new(@claim)
    @task = @claim.tasks.find_or_initialize_by(name: params[:name])
    @current_task_name = current_task_name
    set_pagination
    @notes = if params[:name] == "identity_confirmation"
      @claim.notes.order(created_at: :desc).select do |note|
        note.body =~ %r{National Insurance|Teacher reference|First name or surname|Date of birth|Not matched}
      end
    elsif params[:name] == "qualifications"
      @claim.notes.order(created_at: :desc).select { |note| note.body.include?("ligible") && note.body.include?("ITT start date") }.uniq { |n| n.body }
    elsif params[:name] == "census_subjects_taught"
      @claim.notes.order(created_at: :desc).select { |note| note.body.include?("ligible") && note.body.include?("Subject 1") }
    elsif params[:name] == "employment"
      @claim.notes.order(created_at: :desc).select { |note| note.body.include?("ligible") && note.body.include?("[Employment]") }
    else
      []
    end

    render @task.name
  end

  def create
    @claim_checking_tasks = ClaimCheckingTasks.new(@claim)
    @task = @claim.tasks.build(check_params)
    @current_task_name = current_task_name

    if @task.save
      redirect_to next_task_path
    else
      @tasks_presenter = @claim.policy::AdminTasksPresenter.new(@claim)
      set_pagination
      render @task.name
    end
  end

  def update
    @claim_checking_tasks = ClaimCheckingTasks.new(@claim)
    @task = @claim.tasks.where(name: params[:name]).first
    @current_task_name = current_task_name

    if @task.update(check_params)
      redirect_to next_task_path
    else
      @tasks_presenter = @claim.policy::AdminTasksPresenter.new(@claim)
      set_pagination
      render @task.name
    end
  end

  private

  def load_claim
    @claim = Claim.includes(:tasks).find(params[:claim_id])
  end

  def ensure_task_has_not_already_been_completed
    claim = @claim.tasks.find_by(name: params[:task][:name])

    if claim && !claim.passed.nil?
      redirect_to admin_claim_task_path(@claim, name: params[:task][:name]), alert: "This task has already been completed"
    end
  end

  def check_params
    params.require(:task)
      .permit(:passed, :name)
      .merge(
        created_by: admin_user,
        manual: true
      )
  end

  def load_matching_claims
    @matching_claims = Claim::MatchingAttributeFinder.new(@claim).matching_claims
  end

  def current_task_name
    @task.name
  end
end
