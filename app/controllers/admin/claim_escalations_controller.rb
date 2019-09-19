class Admin::ClaimEscalationsController < Admin::BaseAdminController
  before_action :ensure_service_operator, :fetch_claim

  def new
    @claim.notes.build
  end

  def create
    if @claim.escalate!(escalated_by: admin_session.user_id)
      @claim.notes.create!(created_by: admin_session.user_id, body: params[:claim][:note][:body])
      redirect_to admin_claims_path, notice: "Claim has been escalated successfully"
    else
      redirect_to admin_claim_path(@claim), notice: "Claim cannot be escalated"
    end
  end

  private

  def fetch_claim
    @claim = Claim.find(params[:claim_id])
  end
end
