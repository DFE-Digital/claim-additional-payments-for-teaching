class Admin::ClaimsController < Admin::BaseAdminController
  before_action :ensure_service_operator

  def index
    @claims = Claim.includes(:check, eligibility: [:claim_school, :current_school]).awaiting_checking.order(:submitted_at)
    respond_to do |format|
      format.html
      format.csv {
        send_data Claim::DatabaseOfQualifiedTeachersReportRequest.new(@claims).to_csv,
          filename: "dqt_report_request_#{Date.today.iso8601}.csv"
      }
    end
  end

  def show
    @claim = Claim.find(params[:id])
    @check = @claim.check || Check.new
    @matching_claims = Claim::MatchingAttributeFinder.new(@claim).matching_claims
  end

  def search
    return unless params[:reference].present?

    claim = Claim.find_by(reference: params[:reference].upcase)

    if claim
      redirect_to(admin_claim_url(claim))
    else
      flash.now[:notice] = "Cannot find a claim with reference \"#{params[:reference]}\""
    end
  end
end
