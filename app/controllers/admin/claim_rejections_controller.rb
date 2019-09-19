class Admin::ClaimRejectionsController < Admin::BaseAdminController
  before_action :ensure_service_operator, :fetch_claim, :refuse_checked_claims

  def new
    @note = @claim.notes.build
  end

  def create
    @note = @claim.notes.build(created_by: admin_session.user_id, body: params[:note][:body])

    if @note.valid? && @claim.reject!(rejected_by: admin_session.user_id)
      ClaimMailer.rejected(@claim).deliver_later
      redirect_to admin_claims_path, notice: "Claim has been rejected successfully"
    else
      render :new
    end
  end

  private

  def fetch_claim
    @claim = Claim.find(params[:claim_id])
  end

  def refuse_checked_claims
    redirect_to([:admin, @claim], notice: "Claim already checked") unless @claim.needs_checking?
  end
end
