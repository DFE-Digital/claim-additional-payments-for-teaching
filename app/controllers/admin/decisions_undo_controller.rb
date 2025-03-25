class Admin::DecisionsUndoController < Admin::BaseAdminController
  before_action :load_claim
  before_action :load_decision
  before_action :ensure_service_operator

  def new
    @form = Admin::UndoDecisionForm.new(
      claim: @claim,
      decision: @decision,
      current_admin:
    )
  end

  def create
    @form = Admin::UndoDecisionForm.new(
      claim: @claim,
      decision: @decision,
      current_admin:,
      params: amendment_params
    )

    if @form.valid? && @form.save
      redirect_to admin_claim_tasks_path(@claim)
    else
      render :new
    end
  end

  private

  def load_claim
    @claim = Claim.find(params[:claim_id])
  end

  def load_decision
    @decision = @claim.decisions.find(params[:decision_id])
  end

  def amendment_params
    params.require(:amendment).permit(:notes)
  end
end
