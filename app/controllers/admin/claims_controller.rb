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
    return unless params[:query].present?

    @claims = Claim::Search.new(params[:query]).claims.includes(:eligibility)

    if @claims.none?
      flash.now[:notice] = "Cannot find a claim for query \"#{params[:query]}\""
    elsif @claims.one?
      redirect_to(admin_claim_tasks_url(@claims.first))
    end
  end

  private

  def filtered_policy
    Policies[params[:policy]]
  end
end
