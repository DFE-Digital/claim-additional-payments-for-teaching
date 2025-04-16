# Runs weekly at 00:30 on a Sunday morning, and instructs the PersonalDataScrubber class
# to remove personal data from eligible claims.
class DeletePersonalDataFromOldClaimsJob < ApplicationJob
  def perform
    Rails.logger.info "Deleting personal data from old claims which have been rejected or paid"
    Policies::POLICIES.each do |policy|
      policy::ClaimPersonalDataScrubber.new.scrub_completed_claims
    end
  end
end
