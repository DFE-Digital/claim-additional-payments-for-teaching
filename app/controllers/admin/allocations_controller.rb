require "claim_allocator"
require "claim_deallocator"

# Allows team members to assign/unassign themselves (or other team members) to/from claim(s)
class Admin::AllocationsController < Admin::BaseAdminController
  before_action :ensure_service_operator
  before_action :load_target_claim, only: %i[allocate deallocate]
  before_action :load_team_member, only: %i[bulk_allocate bulk_deallocate]

  def allocate
    ClaimAllocator.new(claim_ids: @claim.id, admin_user_id: admin_user.id).call

    redirect_to request.referrer
  end

  def deallocate
    ClaimDeallocator.new(claim_ids: @claim.id, admin_user_id: @claim.assigned_to_id).call

    redirect_to request.referrer
  end

  def bulk_allocate
    claims = Claim.where(assigned_to: nil).includes(:decisions, eligibility: [:claim_school, :current_school]).awaiting_decision.order(:submitted_at).limit(params[:allocate_claim_count])
    ClaimAllocator.new(claim_ids: claims.map(&:id), admin_user_id: params[:allocate_to]).call

    redirect_to request.referrer, notice: I18n.t("admin.allocations.bulk_allocate.success", quantity: params[:allocate_claim_count], dfe_user: @team_member.full_name)
  end

  def bulk_deallocate
    ClaimDeallocator.new(claim_ids: [], admin_user_id: params[:allocate_to], bulk: true).call

    redirect_to admin_claims_path, notice: I18n.t("admin.allocations.bulk_deallocate.success", dfe_user: @team_member.full_name)
  end

  private

  def load_target_claim
    @claim = Claim.find(params[:id])
  end

  def load_team_member
    @team_member = DfeSignIn::User.find params[:allocate_to]
  end
end
