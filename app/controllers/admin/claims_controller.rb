class Admin::ClaimsController < Admin::BaseAdminController
  before_action :ensure_service_operator

  def index
    @claims = Claim.includes(eligibility: [:claim_school, :current_school]).awaiting_approval.order(:submitted_at)

    respond_to do |format|
      format.csv { send_file TslrClaimsCsv.new(@claims).file, type: "text/csv", filename: "claims.csv" }
      format.html
    end
  end

  def show
    @claim = Claim.find(params[:id])
  end

  def approve
    @claim = Claim.find(params[:id])
    @claim.approve!(approved_by: admin_session.user_id)
    redirect_to admin_claims_path, notice: "Claim has been approved successfully"
  end

  private

  def ensure_service_operator
    render "admin/auth/failure", status: :unauthorized unless service_operator_signed_in?
  end
end
