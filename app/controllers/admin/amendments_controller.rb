class Admin::AmendmentsController < Admin::BaseAdminController
  before_action :load_claim
  before_action :ensure_service_operator
  before_action :ensure_claim_is_amendable

  def new
    @amendment = @claim.amendments.build
  end

  def create
    @amendment = Amendment.amend_claim(@claim, claim_params, amendment_params)

    if @amendment.persisted?
      redirect_to admin_claim_url(@claim)
    else
      render "new"
    end
  end

  private

  def load_claim
    @claim = Claim.find(params[:claim_id])
  end

  def ensure_claim_is_amendable
    unless @claim.amendable?
      render "not_amendable"
    end
  end

  def claim_params
    params.require(:amendment).require(:claim).permit(*amendable_attributes)
  end

  def amendable_attributes
    Claim::AMENDABLE_ATTRIBUTES.dup.concat([eligibility_attributes: Policies::AMENDABLE_ELIGIBILITY_ATTRIBUTES])
  end

  def amendment_params
    {
      notes: params[:amendment][:notes],
      created_by: admin_user
    }
  end
end
