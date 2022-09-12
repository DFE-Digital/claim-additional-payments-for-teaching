class Admin::ClaimsController < Admin::BaseAdminController
  include Pagy::Backend

  before_action :ensure_service_operator

  def index
    @claims = Claim.includes(:decisions, eligibility: [:claim_school, :current_school]).awaiting_decision.order(:submitted_at)
    @claims = @claims.by_policy(filtered_policy) if filtered_policy
    @claims = @claims.by_claims_team_member(filtered_team_member) if filtered_team_member

    all_claims = @claims
    @total_claim_count = all_claims.count
    @pagy, @claims = pagy(@claims)

    respond_to do |format|
      format.html
      format.csv {
        send_data Claim::DataReportRequest.new(all_claims).to_csv,
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

  def filtered_team_member
    return if params[:team_member].blank?

    name = params[:team_member].split("-")
    DfeSignIn::User.find_by(given_name: name.shift, family_name: name).id
  end
end
