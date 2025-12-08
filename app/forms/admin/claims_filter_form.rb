class Admin::ClaimsFilterForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :filters
  attribute :selected_page
  attribute :session

  def initialize(args)
    super

    session[:filter] ||= {}
    session[:page] = nil if filters_changed?
  end

  def filters_changed?
    if filters[:team_member].blank? ||
        filters[:policy].blank? ||
        filters[:status].blank?
      return false
    end

    session_filters = session[:filter]

    (filters[:team_member] != session_filters["team_member"]) ||
      (filters[:policy] != session_filters["policy"]) ||
      (filters[:status] != session_filters["status"])
  end

  def team_member
    return "all" if reset?

    @team_member ||= filters[:team_member] || session[:filter]["team_member"] || "all"
  end

  def policy
    return "all" if reset?

    @policy ||= filters[:policy] || session[:filter]["policy"] || "all"
  end

  def status
    return "awaiting_decision" if reset?

    @status ||= filters[:status] || session[:filter]["status"] || "awaiting_decision"
  end

  def page
    return 1 if reset?

    @page ||= selected_page || session[:page] || 1
  end

  def reset?
    filters[:reset].present?
  end

  def claims
    return @claims if @claims

    @claims =
      case status
      when "approved"
        Claim.current_academic_year.approved
      when "approved_awaiting_qa"
        Claim.approved.awaiting_qa
      when "approved_awaiting_payroll"
        approved_awaiting_payroll
      when "automatically_approved"
        Claim.current_academic_year.auto_approved
      when "quality_assured"
        Claim
          .current_academic_year
          .where.not(qa_completed_at: nil)
      when "quality_assured_approved"
        Claim
          .current_academic_year
          .where.not(qa_completed_at: nil)
          .approved
      when "quality_assured_rejected"
        Claim
          .current_academic_year
          .where.not(qa_completed_at: nil)
          .rejected
      when "automatically_approved_awaiting_payroll"
        Claim
          .payrollable.auto_approved
      when "rejected"
        Claim
          .current_academic_year.rejected
      when "rejected_awaiting_qa"
        Claim
          .rejected_awaiting_qa
      when "held"
        Claim
          .includes(:decisions)
          .held.awaiting_decision
      when "failed_bank_validation"
        Claim
          .includes(:decisions)
          .failed_bank_validation
          .awaiting_decision
      when "awaiting_provider_verification"
        Claim
          .by_policy(Policies::FurtherEducationPayments)
          .awaiting_further_education_provider_verification
          .awaiting_decision
      when "awaiting_claimant_data"
        Claim
          .by_policy(Policies::EarlyYearsPayments)
          .where(submitted_at: nil)
          .awaiting_decision
      when "awaiting_retention_period_completion"
        Claim
          .by_policy(Policies::EarlyYearsPayments)
          .joins(:early_years_payment_eligibility)
          .includes(:early_years_payment_eligibility)
          .where.not(submitted_at: nil)
          .awaiting_decision
          .where("early_years_payment_eligibilities.start_date > ?", Policies::EarlyYearsPayments::RETENTION_PERIOD.ago)
      when "awaiting_retention_check_data"
        Claim
          .by_policy(Policies::EarlyYearsPayments)
          .joins(:early_years_payment_eligibility)
          .includes(:early_years_payment_eligibility)
          .where.not(submitted_at: nil)
          .awaiting_decision
          .where("early_years_payment_eligibilities.start_date < ?", Policies::EarlyYearsPayments::RETENTION_PERIOD.ago)
      when "awaiting_decision"
        Claim
          .includes(:decisions)
          .not_held
          .awaiting_decision
          .not_awaiting_further_education_provider_verification
      else
        raise "Unknown status passed to Admin::ClaimsFilterForm"
      end

    @claims = @claims.by_policy(selected_policy) if selected_policy
    @claims = @claims.by_claims_team_member(selected_team_member, status) if selected_team_member
    @claims = @claims.unassigned if unassigned?

    @claims = Claim.where(id: @claims.select("DISTINCT ON (claims.id) claims.id"))

    @claims = @claims.includes(:tasks, :assigned_to)
    @claims = @claims.order(:submitted_at)

    @claims
  end

  def count
    claims.count
  end

  def policy_select_options
    array = [OpenStruct.new(id: "all", name: "All")]

    array + Policies.all.map do |policy|
      OpenStruct.new(id: policy.policy_type, name: policy.short_name)
    end
  end

  def status_grouped_select_options
    {
      "Awaiting" => {
        "Awaiting decision - not on hold" => "awaiting_decision",
        "Awaiting provider verification" => "awaiting_provider_verification",
        "Awaiting claimant data" => "awaiting_claimant_data",
        "Awaiting retention period completion" => "awaiting_retention_period_completion",
        "Awaiting retention check data" => "awaiting_retention_check_data",
        "Awaiting decision - on hold" => "held",
        "Awaiting decision - failed bank details" => "failed_bank_validation"
      },
      "QA" => {
        "Approved awaiting QA" => "approved_awaiting_qa",
        "Rejected awaiting QA" => "rejected_awaiting_qa",
        "Quality assured" => "quality_assured",
        "Quality assured - approved" => "quality_assured_approved",
        "Quality assured - rejected" => "quality_assured_rejected"
      },
      "Payroll" => {
        "Approved awaiting payroll" => "approved_awaiting_payroll",
        "Automatically approved awaiting payroll" => "automatically_approved_awaiting_payroll"
      },
      "Decisioned" => {
        "Automatically approved" => "automatically_approved",
        "Approved" => "approved",
        "Rejected" => "rejected"
      }
    }
  end

  def team_member_select_options
    array = [["All", "all"], ["Unassigned", "unassigned"]]
    array += DfeSignIn::User.options_for_select

    array.map do |name, id|
      OpenStruct.new(id:, name:)
    end
  end

  def save_to_session!
    session[:filter] = {
      "team_member" => team_member,
      "policy" => policy,
      "status" => status
    }

    session[:page] = page
  end

  private

  def approved_awaiting_payroll
    claim_ids_with_payrollable_topups = Topup.payrollable.pluck(:claim_id)

    Claim.payrollable.or(Claim.where(id: claim_ids_with_payrollable_topups))
  end

  def selected_policy
    return if all_policies?

    Policies[policy]
  end

  def all_policies?
    policy == "all"
  end

  def selected_team_member
    return if all_team_members? || unassigned?

    DfeSignIn::User.admin.not_deleted.find(team_member)
  end

  def all_team_members?
    team_member == "all"
  end

  def unassigned?
    team_member == "unassigned"
  end
end
