class Admin::ClaimsController < Admin::BaseAdminController
  def index
    claims = TslrClaim.includes(eligibility: [:claim_school, :current_school]).submitted.order(:submitted_at)
    csv = TslrClaimsCsv.new(claims)

    respond_to do |format|
      format.csv { send_file csv.file, type: "text/csv", filename: "claims.csv" }
    end
  end
end
