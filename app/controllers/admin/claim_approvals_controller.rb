class Admin::ClaimApprovalsController < Admin::BaseAdminController
  before_action :ensure_service_operator

  def create
    @claim = Claim.find(params[:claim_id])
    if @claim.approve!(approved_by: admin_session.user_id)
      ClaimMailer.approved(@claim).deliver_later
      redirect_to admin_claims_path, notice: "Claim has been approved successfully"
    else
      redirect_to admin_claim_path(@claim), notice: "Claim cannot be approved"
    end
  end
end
