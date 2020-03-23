class Admin::ClaimsController < Admin::BaseAdminController
  before_action :ensure_service_operator

  def index
    @claims = Claim.includes(:decisions, eligibility: [:claim_school, :current_school]).awaiting_decision.order(:submitted_at)
    @claims = @claims.by_policy(filtered_policy) if filtered_policy

    respond_to do |format|
      format.html
      format.csv {
        send_data Claim::DataReportRequest.new(@claims).to_csv,
          filename: "dqt_report_request_#{Date.today.iso8601}.csv"
      }
    end
  end

  def show
    @claim = Claim.find(params[:id])
    @decision = @claim.latest_decision || Decision.new
    @matching_claims = Claim::MatchingAttributeFinder.new(@claim).matching_claims
    @claims_preventing_payment = Claim::ClaimsPreventingPaymentFinder.new(@claim).claims_preventing_payment
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

  private

  def filtered_policy
    Policies[params[:policy]]
  end
end
