class AutoApproveClaimsJob < ApplicationJob
  def perform
    journey_configurations.each do |journey_configuration|
      policy = journey_configuration.journey.policies.first

      claims_awaiting_decision = Claim
        .where(policy:)
        .where(academic_year: journey_configuration.current_academic_year)
        .not_held
        .awaiting_decision

      Rails.logger.info "Checking #{claims_awaiting_decision.count} #{policy} claims for auto-approval"

      claims_awaiting_decision.find_each(batch_size: 100) do |claim|
        AutoApproveClaimJob.perform_later(claim) if ClaimAutoApproval.new(claim).eligible?
      end
    end
  end

  private

  def journey_configurations
    Journeys::Configuration.all
  end
end
