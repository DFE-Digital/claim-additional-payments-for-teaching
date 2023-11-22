class AutoApproveClaimJob < ApplicationJob
  def perform(claim)
    claim_auto_approval = ClaimAutoApproval.new(claim)
    return unless claim_auto_approval.eligible?

    claim_auto_approval.auto_approve!
    Rails.logger.info "Auto-approved claim #{claim.id}"
  rescue ClaimAutoApproval::AutoApprovalFailed
    Rails.logger.error "Failed to auto-approve claim #{claim.id}"
    raise
  end
end
