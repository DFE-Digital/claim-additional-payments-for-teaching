class Admin::ClaimChecksController < Admin::BaseAdminController
  before_action :ensure_service_operator
  before_action :load_claim
  before_action :reject_checked_claims

  def create
    @claim.create_check!(checked_by: admin_session.user_id, result: params[:result])
    ClaimMailer.approved(@claim).deliver_later
    redirect_to admin_claims_path, notice: "Claim has been approved successfully"
  end

  private

  def load_claim
    @claim = Claim.find(params[:claim_id])
  end

  def reject_checked_claims
    if @claim.check.present?
      redirect_to admin_claim_path(@claim), notice: "Claim already checked"
    end
  end
end
