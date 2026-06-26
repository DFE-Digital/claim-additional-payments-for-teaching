class BackfillMatchingDetailsTask < ApplicationJob
  def self.enqueue
    Claim
      .by_academic_year(AcademicYear.current)
      .find_each { |claim| perform_later(claim) }
  end

  def perform(claim)
    AutomatedChecks::ClaimVerifiers::MatchingClaims.new(claim: claim).perform
  end

  def priority
    15
  end
end
