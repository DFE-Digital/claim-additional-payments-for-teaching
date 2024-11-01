class Admin::ClaimsFilterForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :filters
  attribute :session

  def initialize(args)
    super

    session[:filter] ||= {}
  end

  def team_member
    return if reset?

    @team_member ||= filters[:team_member] || session[:filter]["team_member"]
  end

  def policy
    return if reset?

    @policy ||= filters[:policy] || session[:filter]["policy"]
  end

  def status
    return if reset?

    @status ||= filters[:status] || session[:filter]["status"]
  end

  def filters_applied?
    team_member.present? || policy.present? || status.present?
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
        Claim.current_academic_year.payrollable.auto_approved
      when "rejected"
        Claim.current_academic_year.rejected
      when "held"
        Claim.includes(:decisions).held.awaiting_decision
      when "failed_bank_validation"
        Claim.includes(:decisions).failed_bank_validation.awaiting_decision
      when "awaiting_provider_verification"
        Claim.by_policy(Policies::FurtherEducationPayments).awaiting_further_education_provider_verification.awaiting_decision
      when "awaiting_claimant_data"
        Claim
          .by_policy(Policies::EarlyYearsPayments)
          .where(submitted_at: nil)
          .awaiting_decision
      when "awaiting_retention_period_completion"
        Claim
          .by_policy(Policies::EarlyYearsPayments)
          .joins(:early_years_payment_eligibility)
          .where.not(submitted_at: nil)
          .awaiting_decision
          .where("early_years_payment_eligibilities.start_date > ?", Policies::EarlyYearsPayments::RETENTION_PERIOD.ago)
      when "awaiting_retention_check_data"
        Claim
          .by_policy(Policies::EarlyYearsPayments)
          .joins(:early_years_payment_eligibility)
          .where.not(submitted_at: nil)
          .awaiting_decision
          .where("early_years_payment_eligibilities.start_date < ?", Policies::EarlyYearsPayments::RETENTION_PERIOD.ago)
      else
        Claim.includes(:decisions).not_held.awaiting_decision.not_awaiting_further_education_provider_verification
      end

    @claims = @claims.by_policy(selected_policy) if selected_policy
    @claims = @claims.by_claims_team_member(selected_team_member, status) if selected_team_member
    @claims = @claims.unassigned if unassigned?

    @claims = Claim.where(id: @claims.select("DISTINCT ON (claims.id) claims.id"))

    @claims = @claims.includes(:tasks, eligibility: [:claim_school, :current_school])

    @claims = @claims.order(:submitted_at)
    @claims
  end

  def count
    claims.count
  end

  def policy_select_options
    array = [OpenStruct.new(id: nil, name: "All")]

    array + Policies.all.map do |policy|
      OpenStruct.new(id: policy.policy_type, name: policy.short_name)
    end
  end

  def status_grouped_select_options
    {
      "Awaiting" => {
        "Awaiting decision - not on hold" => nil,
        "Awaiting provider verification" => "awaiting_provider_verification",
        "Awaiting claimant data" => "awaiting_claimant_data",
        "Awaiting retention period completion" => "awaiting_retention_period_completion",
        "Awaiting retention check data" => "awaiting_retention_check_data",
        "Awaiting decision - on hold" => "held",
        "Awaiting decision - failed bank details" => "failed_bank_validation"
      },
      "QA" => {
        "Approved awaiting QA" => "approved_awaiting_qa",
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
    array = [["All", nil], ["Unassigned", "unassigned"]]
    array += DfeSignIn::User.options_for_select

    array.map do |name, id|
      OpenStruct.new(id:, name:)
    end
  end

  def save_to_session!
    session[:filter] = {
      team_member:,
      policy:,
      status:
    }
  end

  private

  def approved_awaiting_payroll
    claim_ids_with_payrollable_topups = Topup.payrollable.pluck(:claim_id)

    Claim.current_academic_year.payrollable.or(Claim.current_academic_year.where(id: claim_ids_with_payrollable_topups))
  end

  def selected_policy
    Policies[policy]
  end

  def selected_team_member
    return if team_member.blank? || unassigned?

    DfeSignIn::User.not_deleted.find(team_member)
  end

  def unassigned?
    team_member == "unassigned"
  end
end
