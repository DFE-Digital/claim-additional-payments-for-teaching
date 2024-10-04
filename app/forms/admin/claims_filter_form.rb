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
    filters[:team_member] || session[:filter][:team_member]
  end

  def policy
    return if reset?

    filters[:policy] || session[:filter][:policy]
  end

  def status
    return if reset?

    filters[:status] || session[:filter][:status]
  end

  def filters_applied?
    return if reset?

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
      when "automatically_approved_awaiting_payroll"
        Claim.current_academic_year.payrollable.auto_approved
      when "rejected"
        Claim.current_academic_year.rejected
      when "held"
        Claim.includes(:decisions).held.awaiting_decision
      when "failed_bank_validation"
        Claim.includes(:decisions).failed_bank_validation.awaiting_decision
      when "awaiting_provider_verification"
        Claim.by_policy(Policies::FurtherEducationPayments).awaiting_further_education_provider_verification
      else
        Claim.includes(:decisions).not_held.awaiting_decision.not_awaiting_further_education_provider_verification
      end

    @claims = @claims.by_policy(selected_policy) if selected_policy
    @claims = @claims.by_claims_team_member(selected_team_member, status) if selected_team_member
    @claims = @claims.unassigned if unassigned?

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

  def status_select_options
    [
      ["Awaiting decision - not on hold", nil],
      ["Awaiting provider verification", "awaiting_provider_verification"],
      ["Awaiting decision - on hold", "held"],
      ["Awaiting decision - failed bank details", "failed_bank_validation"],
      ["Approved awaiting QA", "approved_awaiting_qa"],
      ["Approved awaiting payroll", "approved_awaiting_payroll"],
      ["Automatically approved awaiting payroll", "automatically_approved_awaiting_payroll"],
      ["Approved", "approved"],
      ["Rejected", "rejected"]
    ].map do |name, id|
      OpenStruct.new(id:, name:)
    end
  end

  def team_member_select_options
    array = [["All", nil], ["Unassigned", "unassigned"]]
    array = array + DfeSignIn::User.options_for_select

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
