class AutoApproveClaimsJob < ApplicationJob
  def perform
    Rails.logger.info "Checking #{claims_awaiting_decision.count} claims for auto-approval"

    claims_awaiting_decision.find_each(batch_size: 100) do |claim|
      AutoApproveClaimJob.perform_later(claim) if ClaimAutoApproval.new(claim).eligible?
    end
  end

  private

  def claims_awaiting_decision
    @claims_awaiting_decision ||= Claim.current_academic_year.not_held.awaiting_decision
  end
end
