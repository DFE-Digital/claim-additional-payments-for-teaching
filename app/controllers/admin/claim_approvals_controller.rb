class Admin::ClaimApprovalsController < Admin::BaseAdminController
  before_action :ensure_service_operator

  def create
    @claim = Claim.find(params[:claim_id])
    @claim.approve!(approved_by: admin_session.user_id)
    redirect_to admin_claims_path, notice: "Claim has been approved successfully"
  end
end
