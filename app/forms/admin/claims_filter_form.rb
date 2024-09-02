class Admin::ClaimsFilterForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :team_member, :string
  attribute :policy, :string
  attribute :status, :string

  def claims
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
      end

    @claims ||= Claim.includes(:decisions).not_held.awaiting_decision

    @claims = @claims.by_policy(filtered_policy) if filtered_policy
    @claims = @claims.by_claims_team_member(filtered_team_member, status) if filtered_team_member
    @claims = @claims.unassigned if filtered_unassigned

    @claims = @claims.includes(:tasks, eligibility: [:claim_school, :current_school])
    @claims = @claims.order(:submitted_at)

    @claims
  end

  def count
    claims.count
  end

  private

  def approved_awaiting_payroll
    claim_ids_with_payrollable_topups = Topup.payrollable.pluck(:claim_id)

    Claim.current_academic_year.payrollable.or(Claim.current_academic_year.where(id: claim_ids_with_payrollable_topups))
  end

  def filtered_policy
    Policies[policy]
  end

  def filtered_team_member
    return if team_member.blank? || filtered_unassigned
    DfeSignIn::User.not_deleted.find(team_member).id
  end

  def filtered_unassigned
    team_member == "unassigned"
  end
end
