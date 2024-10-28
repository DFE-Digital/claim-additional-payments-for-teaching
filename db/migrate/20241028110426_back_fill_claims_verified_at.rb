class BackFillClaimsVerifiedAt < ActiveRecord::Migration[7.0]
  def change
    Policies::FurtherEducationPayments::Eligibility
      .includes(:claim).where.not(verification: {}).find_each do |eligibility|
        eligibility.claim.update!(verified_at: eligibility.verification["created_at"])
      end
  end
end
