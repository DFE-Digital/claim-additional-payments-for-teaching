class Admin::DecisionsUndoController < Admin::BaseAdminController
  before_action :load_claim
  before_action :load_decision

  before_action :ensure_service_operator

  def new
    @amendment = Amendment.new
  end

  def create
    @amendment = Amendment.undo_decision(@decision, amendment_params)

    if @amendment.persisted?
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
    {
      notes: params[:amendment][:notes],
      created_by: admin_user
    }
  end
end
