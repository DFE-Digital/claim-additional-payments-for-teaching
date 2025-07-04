class Admin::TasksController < Admin::BaseAdminController
  before_action :ensure_service_operator
  before_action :load_claim
  before_action :ensure_task_has_not_already_been_completed, only: [:create]
  before_action :load_matching_claims, only: [:show], if: :load_matching_claims?

  def index
    @claim_checking_tasks = ClaimCheckingTasks.new(@claim)
    @banner_messages = set_banner_messages
  end

  def show
    @claim_checking_tasks = ClaimCheckingTasks.new(@claim)
    @tasks_presenter = @claim.policy::AdminTasksPresenter.new(@claim)
    @form = form_class.new(name:, claim: @claim)
    @notes = @claim.notes.automated.by_label(params[:name])
    @task_pagination = Admin::TaskPagination.new(claim: @claim, current_task_name: @form.task.name)

    render task_view(@form.task)
  end

  def create
    @claim_checking_tasks = ClaimCheckingTasks.new(@claim)
    @form = form_class.new(form_params.merge(name:, claim: @claim))
    @task_pagination = Admin::TaskPagination.new(claim: @claim, current_task_name: @form.task.name)

    if @form.save
      redirect_to @task_pagination.next_task_path
    else
      load_matching_claims if load_matching_claims?
      @tasks_presenter = @claim.policy::AdminTasksPresenter.new(@claim)
      render name
    end
  end

  def update
    @claim_checking_tasks = ClaimCheckingTasks.new(@claim)
    @form = form_class.new(form_params.merge(name:, claim: @claim))
    @task_pagination = Admin::TaskPagination.new(claim: @claim, current_task_name: @form.task.name)

    if @form.task.update(form_params)
      redirect_to @task_pagination.next_task_path
    else
      @tasks_presenter = @claim.policy::AdminTasksPresenter.new(@claim)
      render name
    end
  end

  private

  def form_class
    Admin::Tasks::FormFactory.form_for_task(name)
  end

  # task_name
  def name
    params.fetch(:form, {})[:name] || params[:name]
  end

  def load_claim
    @claim = Claim.includes(:tasks).find(params[:claim_id])
  end

  def ensure_task_has_not_already_been_completed
    claim = @claim.tasks.find_by(name: params[:name])

    if claim && !claim.passed.nil?
      redirect_to admin_claim_task_path(@claim, name: params[:task][:name]), alert: "This task has already been completed"
    end
  end

  def form_params
    params.require(:form)
      .permit(*form_class.permitted_params)
      .merge(
        admin_user:
      )
  end

  def load_matching_claims
    @matching_claims = Claim::MatchingAttributeFinder.new(@claim).matching_claims
  end

  def load_matching_claims?
    params[:name] == "matching_details"
  end

  def set_banner_messages
    messages = []

    if Claim::MatchingAttributeFinder.new(@claim).matching_claims.exists?
      claims_link = view_context.link_to(
        "Multiple claims",
        admin_claim_task_path(claim_id: @claim.id, name: "matching_details"),
        class: "govuk-notification-banner__link"
      )

      messages << "#{claims_link} with matching details have been made in this claim window.".html_safe
    end

    if @claim.attributes_flagged_by_risk_indicator.any?
      messages << <<~MSG.html_safe
        This claim has been flagged as the
        #{@claim.attributes_flagged_by_risk_indicator.map(&:humanize).to_sentence.downcase}
        #{@claim.attributes_flagged_by_risk_indicator.many? ? "are" : "is"}
        included on the fraud prevention list. Speak to a manager.
      MSG
    end

    messages
  end

  def task_view(task)
    policy = task.claim.policy
    policy_path = policy.to_s.underscore
    policy_scoped_task_name = "#{policy_path}/#{task.name}"

    if lookup_context.template_exists?(policy_scoped_task_name, [params[:controller]], false)
      "admin/tasks/#{policy_scoped_task_name}"
    else
      task.name
    end
  end
end
