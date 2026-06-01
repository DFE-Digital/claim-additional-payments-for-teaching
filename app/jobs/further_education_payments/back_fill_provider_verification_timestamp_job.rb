module FurtherEducationPayments
  class BackFillProviderVerificationTimestampJob < ApplicationJob
    def perform
      scope = Policies::FurtherEducationPayments::Eligibility
        .joins(:claim)
        .merge(Claim.by_academic_year(AcademicYear.new(2024)))
        .where("further_education_payments_eligibilities.verification->>'created_at' IS NOT NULL")

      scope.find_each do |eligibility|
        eligibility.update!(
          provider_verification_completed_at: eligibility.verification["created_at"]
        )
      end
    end
  end
end
