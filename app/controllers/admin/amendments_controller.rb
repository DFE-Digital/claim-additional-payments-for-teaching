class Admin::AmendmentsController < Admin::BaseAdminController
  before_action :ensure_service_operator

  def new
    @claim = Claim.find(params[:claim_id])
    @amendment = @claim.amendments.build
  end

  def create
    @claim = Claim.find(params[:claim_id])
    @amendment = Amendment.amend_claim(@claim, claim_params, amendment_params)

    if @amendment.persisted?
      redirect_to admin_claim_url(@claim)
    else
      render "new"
    end
  end

  private

  def claim_params
    params.require(:amendment).require(:claim).permit(*Claim::AMENDABLE_ATTRIBUTES)
  end

  def amendment_params
    {
      notes: params[:amendment][:notes],
      created_by: admin_user
    }
  end
end
