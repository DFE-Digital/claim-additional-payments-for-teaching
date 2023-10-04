class Admin::ClaimsController < Admin::BaseAdminController
  include Pagy::Backend

  before_action :ensure_service_operator
  before_action :filter_claims_by_status, only: :index

  def index
    @claims ||= Claim.includes(:decisions).not_held.awaiting_decision

    @claims = @claims.by_policy(filtered_policy) if filtered_policy
    @claims = @claims.by_claims_team_member(filtered_team_member, params[:status]) if filtered_team_member
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

  def filtered_policy
    Policies[params[:policy]]
  end

  def filtered_team_member
    return if params[:team_member].blank? || filtered_unassigned
    DfeSignIn::User.not_deleted.find(params[:team_member]).id
  end

  def filtered_unassigned
    params[:team_member] == "unassigned"
  end

  # Stores where View Claim originated from, e.g. claims index or search results
  def claims_backlink_path!(source_path)
    session[:claims_backlink_path] = source_path
  end

  def hold_params
    params.require(:hold).permit(:body).merge(claim: @claim)
  end

  def filter_claims_by_status
    @claims =
      case params[:status]
      when "approved"
        Claim.current_academic_year.approved
      when "approved_awaiting_qa"
        Claim.approved.awaiting_qa
      when "approved_awaiting_payroll"
        approved_awaiting_payroll
      when "automatically_approved_awaiting_payroll"
        Claim.current_academic_year.payrollable.auto_approved
      when "rejected"
        Claim.current_academic_year.rejected
      when "held"
        Claim.includes(:decisions).held.awaiting_decision
      when "failed_bank_validation"
        Claim.includes(:decisions).failed_bank_validation.awaiting_decision
      end
  end

  def approved_awaiting_payroll
    claim_ids_with_payrollable_topups = Topup.payrollable.pluck(:claim_id)

    Claim.current_academic_year.payrollable.or(Claim.current_academic_year.where(id: claim_ids_with_payrollable_topups))
  end
end
