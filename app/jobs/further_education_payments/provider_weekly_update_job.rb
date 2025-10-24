module FurtherEducationPayments
  class ProviderWeeklyUpdateJob < ApplicationJob
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
        .includes(eligibility: :provider_assigned_to)

      # Filter out claims that have already been sent today (idempotency check)
      claims_to_send = claims.reject do |claim|
        claim.eligibility.provider_verification_email_last_sent_at&.to_date == Date.current
      end

      # Group claims by provider_assigned_to_id
      unverified_claims = claims_to_send.group_by do |claim|
        claim.eligibility.provider_assigned_to_id
      end

      unverified_claims.each do |provider_id, claims|
        provider_user = claims.first.eligibility.provider_assigned_to

        # Send weekly update email
        FurtherEducationPaymentsMailer
          .with(provider: provider_user, claims: claims)
          .provider_weekly_update
          .deliver_later

        # Update email tracking for all claims
        # Use individual updates to ensure proper incrementing and idempotency
        claims.each do |claim|
          eligibility = claim.eligibility
          # Skip if already sent today
          next if eligibility.provider_verification_email_last_sent_at&.to_date == Date.current

          eligibility.update!(
            provider_verification_email_last_sent_at: Time.current,
            provider_verification_email_count: (eligibility.provider_verification_email_count || 0) + 1
          )
        end
      end
    end
  end
end
