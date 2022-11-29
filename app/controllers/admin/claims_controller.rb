class Admin::ClaimsController < Admin::BaseAdminController
  include Pagy::Backend

  before_action :ensure_service_operator

  def index
    @claims = Claim.current_academic_year.approved if params[:status] == "approved"
    @claims = Claim.current_academic_year.payrollable if params[:status] == "approved_awaiting_payroll"
    @claims = Claim.current_academic_year.rejected if params[:status] == "rejected"
    @claims ||= Claim.includes(:decisions).awaiting_decision

    @claims = @claims.by_policy(filtered_policy) if filtered_policy
    @claims = @claims.by_claims_team_member(filtered_team_member) if filtered_team_member
    @claims = @claims.unassigned if filtered_unassigned

    @claims = @claims.includes(:tasks, eligibility: [:claim_school, :current_school])
    @claims = @claims.order(:submitted_at)

    all_claims = @claims
    @total_claim_count = all_claims.count
    @pagy, @claims = pagy(@claims)

    respond_to do |format|
      format.html {
        claims_backlink_path!(admin_claims_path(
          team_member: params[:team_member],
          policy: params[:policy],
          status: params[:status],
          commit: params[:commit]
        ))
      }
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
      claims_backlink_path!(search_admin_claims_path)
      redirect_to(admin_claim_tasks_url(@claims.first))
    else
      claims_backlink_path!(search_admin_claims_path(query: params[:query]))
    end
  end

  private

  def filtered_policy
    Policies[params[:policy]]
  end

  def filtered_team_member
    return if params[:team_member].blank? || filtered_unassigned

    name = params[:team_member].split("-")
    DfeSignIn::User.not_deleted.find_by(given_name: name.shift, family_name: name).id
  end

  def filtered_unassigned
    params[:team_member] == "unassigned"
  end

  # Stores where View Claim originated from, e.g. claims index or search results
  def claims_backlink_path!(source_path)
    session[:claims_backlink_path] = source_path
  end
end
