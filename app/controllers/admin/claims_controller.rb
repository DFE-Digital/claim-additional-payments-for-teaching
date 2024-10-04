class Admin::ClaimsController < Admin::BaseAdminController
  include Pagy::Backend

  before_action :ensure_service_operator

  def index
    @filter_form = Admin::ClaimsFilterForm.new(
      team_member: filter_params[:team_member],
      policy: filter_params[:policy],
      status: filter_params[:status]
    )

    @pagy, @claims = pagy(@filter_form.claims)

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
        # "Download report request file" button (doesn't use the filters)
        report_request_claims = Claim.includes(:decisions).awaiting_decision
        send_data Claim::DataReportRequest.new(report_request_claims).to_csv,
          filename: "dqt_report_request_#{Date.today.iso8601}.csv"
      }
    end
  end

  def show
    @claim = Claim.submitted.find(params[:id])
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

  def hold
    @claim = Claim.find(params[:claim_id])
    @hold_note = Note.new(hold_params)

    if @hold_note.valid?(:hold_claim)
      @claim.hold!(reason: @hold_note.body, user: admin_user)
      redirect_to admin_claim_notes_path(@claim)
    else
      @note = Note.new
      render "admin/notes/index"
    end
  end

  def unhold
    @claim = Claim.find(params[:claim_id])
    @claim.unhold!(user: admin_user)
    redirect_to admin_claim_notes_path(@claim)
  end

  private

  # Stores where View Claim originated from, e.g. claims index or search results
  def claims_backlink_path!(source_path)
    session[:claims_backlink_path] = source_path
  end

  def hold_params
    params.require(:hold).permit(:body).merge(claim: @claim)
  end

  def filter_params
    params
      .fetch(:filter, {})
      .permit(:team_member, :policy, :status)
  end
end
