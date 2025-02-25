class Admin::DecisionsController < Admin::BaseAdminController
  before_action :ensure_service_operator
  before_action :load_claim
  before_action :reject_decided_claims, only: [:new, :create], unless: -> { qa_decision_task? }
  before_action :reject_missing_payroll_gender, only: [:create]
  before_action :reject_if_claims_preventing_payment, only: [:create]

  def index
    @decisions = @claim.decisions.order(created_at: :asc)
    @task_pagination = Admin::TaskPagination.new(claim: @claim, current_task_name:)
  end

  def new
    @decision = Decision.new
    @claim_checking_tasks = ClaimCheckingTasks.new(@claim)
    @claims_preventing_payment = claims_preventing_payment_finder.claims_preventing_payment
    @task_pagination = Admin::TaskPagination.new(claim: @claim, current_task_name:)
  end

  def create
    @decision = @claim.decisions.build(decision_params.merge(created_by: admin_user))
    @claim_checking_tasks = ClaimCheckingTasks.new(@claim)
    save_decision!
    send_claim_result_email
    redirect_after_decision
  rescue ActiveRecord::RecordInvalid
    @claims_preventing_payment = claims_preventing_payment_finder.claims_preventing_payment
    @task_pagination = Admin::TaskPagination.new(claim: @claim, current_task_name:)
    render "new"
  end

  private

  def load_claim
    @claim = Claim.includes(:tasks).find(params[:claim_id])
    @matching_claims = Claim::MatchingAttributeFinder.new(@claim).matching_claims
  end

  def claims_preventing_payment_finder
    @claims_preventing_payment_finder ||= Claim::ClaimsPreventingPaymentFinder.new(@claim)
  end

  def reject_decided_claims
    if @claim.latest_decision.present?
      redirect_to admin_claim_path(@claim), notice: "Claim outcome already decided"
    end
  end

  def reject_missing_payroll_gender
    if ActiveModel::Type::Boolean.new.cast(decision_params[:approved]) && @claim.payroll_gender_missing?
      redirect_to admin_claim_path(@claim), alert: "Claim cannot be approved"
    end
  end

  def reject_if_claims_preventing_payment
    if ActiveModel::Type::Boolean.new.cast(decision_params[:approved]) && claims_preventing_payment_finder.claims_preventing_payment.any?
      redirect_to admin_claim_path(@claim), alert: "Claim cannot be approved because there are inconsistent claims"
    end
  end

  def save_decision!
    ActiveRecord::Base.transaction do
      @decision.save!

      if qa_decision_task?
        @claim.previous_decision.update!(undone: true)
        @claim.update!(qa_completed_at: Time.zone.now)
      elsif @claim.flaggable_for_qa?
        @claim.update!(qa_required: true)
        @claim.notes.create!(body: "This claim has been marked for a quality assurance review")
      end
    end
  end

  def redirect_after_decision
    if @claim.awaiting_qa?
      redirect_to admin_claim_tasks_path(@claim), notice: "Claim has been #{@claim.latest_decision.result} successfully",
        alert: "This claim has been marked for a quality assurance review"
    else
      redirect_to admin_claims_path, notice: "Claim has been #{@claim.latest_decision.result} successfully"
    end
  end

  def send_claim_result_email
    return if @claim.awaiting_qa?

    @claim.policy.mailer.approved(@claim).deliver_later if @claim.latest_decision.approved?

    if @claim.latest_decision.rejected? && @claim.email_address.present?
      ClaimMailer.rejected(@claim).deliver_later
    end

    if @claim.latest_decision.rejected? && @claim.has_early_years_policy?
      ClaimMailer.rejected_provider_notification(@claim).deliver_later
    end
  end

  def decision_params
    params.require(:decision).permit(:approved, :notes, *rejected_reasons_params)
  end

  def rejected_reasons_params
    Decision.rejected_reasons_for(@claim.policy).map { |r| :"rejected_reasons_#{r}" }
  end

  def qa_decision_task?
    @qa_decision_task ||= params[:qa] == "true" && @claim.awaiting_qa?
  end

  def current_task_name
    if params[:qa] == "true"
      "qa_decision"
    else
      "decision"
    end
  end
end
