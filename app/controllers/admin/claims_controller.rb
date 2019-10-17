class Admin::ClaimsController < Admin::BaseAdminController
  before_action :ensure_service_operator

  def index
    @claims = Claim.includes(:check, eligibility: [:claim_school, :current_school]).awaiting_checking.order(:submitted_at)
  end

  def show
    @claim = Claim.find(params[:id])
  end
end
