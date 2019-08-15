class Admin::ClaimsController < Admin::BaseAdminController
  before_action :ensure_admin_user

  def index
    claims = Claim.includes(eligibility: [:claim_school, :current_school]).submitted.order(:submitted_at)
    csv = TslrClaimsCsv.new(claims)

    respond_to do |format|
      format.csv { send_file csv.file, type: "text/csv", filename: "claims.csv" }
    end
  end

  private

  def ensure_admin_user
    redirect_to admin_path unless is_admin_user?
  end
end
