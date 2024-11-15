require "claim_allocator"
require "claim_deallocator"

# Allows team members to assign/unassign themselves (or other team members) to/from claim(s)
class Admin::AllocationsController < Admin::BaseAdminController
  before_action :ensure_service_operator
  before_action :load_target_claim, only: %i[allocate deallocate]
  before_action :load_team_member, only: %i[bulk_allocate bulk_deallocate]
  before_action :ensure_user_confirmed, only: :bulk_deallocate

  def allocate
    ClaimAllocator.new(claim_ids: @claim.id, admin_user_id: admin_user.id).call

    redirect_to request.referrer
  end

  def deallocate
    ClaimDeallocator.new(claim_ids: @claim.id, admin_user_id: @claim.assigned_to_id).call

    redirect_to request.referrer
  end

  def bulk_allocate
    claims = Claim
      .where(assigned_to: nil)
      .includes(:decisions, eligibility: [:claim_school, :current_school])
      .awaiting_decision
      .order(:submitted_at)
      .limit(params[:allocate_claim_count]
    )
    claims = claims.by_policy(filtered_policy) if filtered_policy

    redirect_to admin_claims_path,
      notice: I18n.t(
        "admin.allocations.bulk_allocate.info",
        allocate_to_policy: policy_name,
        dfe_user: @team_member.full_name.titleize
      ) and return if claims.size.zero?

    ClaimAllocator.new(
      claim_ids: claims.map(&:id),
      admin_user_id: params[:allocate_to_team_member]
    ).call

    redirect_to request.referrer,
      notice: I18n.t(
        "admin.allocations.bulk_allocate.success",
        quantity: claims.size,
        pluralized_or_singular_claim: "claim".pluralize(claims.size),
        allocate_to_policy: policy_name,
        dfe_user: @team_member.full_name.titleize
      )
  end

  def bulk_deallocate
    claims = Claim.where(assigned_to_id: @team_member.id)
    claims = claims.by_policy(filtered_policy) if filtered_policy

    redirect_to admin_claims_path,
      notice: I18n.t(
        "admin.allocations.bulk_deallocate.info",
        allocate_to_policy: policy_name,
        dfe_user: @team_member.full_name.titleize
      ) and return if claims.size.zero?

    ClaimDeallocator.new(
      claim_ids: claims.ids,
      admin_user_id: @team_member.id
    ).call

    redirect_to admin_claims_path,
      notice: I18n.t(
        "admin.allocations.bulk_deallocate.success",
        allocate_to_policy: policy_name,
        dfe_user: @team_member.full_name.titleize
      ) and return
  end

  helper_method :filtered_policy

  private

  def load_target_claim
    @claim = Claim.find(params[:id])
  end

  def load_team_member
    @team_member = DfeSignIn::User.find(params[:allocate_to_team_member])
  end

  def filtered_policy
    Policies[params[:allocate_to_policy]]
  end

  def ensure_user_confirmed
    return if user_confirmed?

    render :bulk_deallocate, locals: {team_member_id:, policy_name:}
  end

  def team_member_id
    params[:allocate_to_team_member]
  end

  def policy_name
    if filtered_policy.present?
      filtered_policy.short_name
    end
  end

  def user_confirmed?
    params[:user_confirmation] == "yes"
  end
end
