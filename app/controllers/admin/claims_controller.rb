class Admin::ClaimsController < Admin::BaseAdminController
  before_action :ensure_service_operator

  def index
    @claims = Claim.includes(eligibility: [:claim_school, :current_school]).awaiting_approval.order(:submitted_at)

    respond_to do |format|
      format.csv { send_file StudentLoansClaimsCsv.new(@claims).file, type: "text/csv", filename: "claims.csv" }
      format.html
    end
  end

  def show
    @claim = Claim.find(params[:id])
  end

  def payroll
    claims = Claim.includes(eligibility: [:claim_school, :current_school]).awaiting_approval.order(:submitted_at)
    csv = PayrollDataCsv.new(claims)

    respond_to do |format|
      format.csv { send_file csv.file, type: "text/csv", filename: "payroll_data.csv" }
    end
  end
end
