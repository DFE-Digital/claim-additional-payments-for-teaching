class Admin::ClaimRejectionsController < Admin::BaseAdminController
  before_action :ensure_service_operator, :fetch_claim

  def create
    if @claim.reject!(rejected_by: admin_session.user_id)
      redirect_to admin_claims_path, notice: "Claim has been rejected successfully"
    else
      redirect_to admin_claim_path(@claim), notice: "Claim cannot be rejected"
    end
  end

  private

  def fetch_claim
    @claim = Claim.find(params[:claim_id])
  end
end
