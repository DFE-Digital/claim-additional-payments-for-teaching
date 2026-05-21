class Admin::DecisionsController < Admin::BaseAdminController
  before_action :ensure_service_operator
  before_action :load_claim

  def index
    @decisions = @claim.decisions.includes(:created_by).order(created_at: :asc)
    @task_pagination = Admin::TaskPagination.new(claim: @claim, current_task_name:)
  end

  def new
    if !qa? && @claim.latest_decision.present?
      return redirect_to admin_claim_path(@claim), notice: "Claim outcome already decided"
    end

    @claim_checking_tasks = ClaimCheckingTasks.new(@claim)
    @decision_form = Admin::DecisionForm.new(claim: @claim, qa: qa?, current_admin: admin_user)
    @claims_preventing_payment = claims_preventing_payment_finder.claims_preventing_payment
    @task_pagination = Admin::TaskPagination.new(claim: @claim, current_task_name:)
  end

  def create
    @decision_form = Admin::DecisionForm.new(claim: @claim, qa: qa?, current_admin: admin_user, params: decision_params)
    @claim_checking_tasks = ClaimCheckingTasks.new(@claim)

    if @decision_form.save
      redirect_after_decision
    else
      @claims_preventing_payment = claims_preventing_payment_finder.claims_preventing_payment
      @task_pagination = Admin::TaskPagination.new(claim: @claim, current_task_name:)
      render "new"
    end
  end

  private

  def load_claim
    @claim = Claim.find(params[:claim_id])
    @matches = Claims::Match.matches_shim(@claim)
  end

  def claims_preventing_payment_finder
    @claims_preventing_payment_finder ||= Claim::ClaimsPreventingPaymentFinder.new(@claim)
  end

  def redirect_after_decision
    if @claim.awaiting_qa?
      redirect_to admin_claim_tasks_path(@claim), notice: "Claim has been #{@claim.latest_decision.result} successfully",
        alert: "This claim has been marked for a quality assurance review"
    else
      redirect_to admin_claims_path, notice: "Claim has been #{@claim.latest_decision.result} successfully"
    end
  end

  def decision_params
    params.require(:decision).permit(:approved, :notes, rejected_reasons: [])
  end

  def qa?
    params[:qa] == "true" && @claim.awaiting_qa?
  end

  def current_task_name
    if params[:qa] == "true"
      "qa_decision"
    else
      "decision"
    end
  end
end
