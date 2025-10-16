module FurtherEducationPayments
  class ProviderOverdueChaserJob < ApplicationJob
    queue_as :user_data

    # Temporal safeguard: don't send emails for claims older than this
    CUTOFF_PERIOD = 6.months

    def perform
      # Find all unverified FE eligibilities with assigned providers
      unverified_eligibility_ids = Policies::FurtherEducationPayments::Eligibility
        .where(provider_verification_completed_at: nil)
        .where.not(provider_assigned_to_id: nil)
        .pluck(:id)

      # Get claims for these eligibilities, filtered by current academic year and recent creation
      claims = Claim
        .where(policy: "Policies::FurtherEducationPayments")
        .where(eligibility_type: "Policies::FurtherEducationPayments::Eligibility")
        .where(eligibility_id: unverified_eligibility_ids)
        .by_academic_year(AcademicYear.current)
        .where("claims.created_at > ?", CUTOFF_PERIOD.ago)
        .includes(:eligibility)

      overdue_claims = claims.select { |claim| eligible_for_chaser?(claim) }

      overdue_claims.each do |claim|
        # Send individual overdue chaser email
        FurtherEducationPaymentsMailer
          .with(claim: claim)
          .provider_overdue_chaser
          .deliver_later

        # Update chaser tracking
        claim.eligibility.update!(
          provider_verification_chase_email_last_sent_at: Time.current,
          provider_verification_email_count: claim.eligibility.provider_verification_email_count + 1
        )
      end
    end

    private

    def eligible_for_chaser?(claim)
      eligibility = claim.eligibility

      # Must be overdue
      return false unless Policies::FurtherEducationPayments.verification_overdue?(claim)

      # Must have received at least the weekly email (count >= 1)
      return false if eligibility.provider_verification_email_count < 1

      # Max 3 chasers (count goes: 0 -> 1 (weekly) -> 2,3,4 (chasers 1,2,3))
      return false if eligibility.provider_verification_email_count >= 4

      # If this would be first chaser (count is 1), check weekly email was sent at least 1 week ago
      if eligibility.provider_verification_email_count == 1
        return false unless eligibility.provider_verification_email_last_sent_at.present?
        return false unless eligibility.provider_verification_email_last_sent_at < 1.week.ago
      end

      # For subsequent chasers (count >= 2), check last chaser was at least 1 week ago
      if eligibility.provider_verification_email_count >= 2
        return false unless eligibility.provider_verification_chase_email_last_sent_at.present?
        return false unless eligibility.provider_verification_chase_email_last_sent_at < 1.week.ago
      end

      true
    end
  end
end
