module EarlyYearsPayments
  class PractitionerReminderEmailJob < ApplicationJob
    REMINDER_INTERVALS = {
      1 => 1.week,
      2 => 2.weeks,
      3 => 4.weeks
    }.freeze

    # Safeguard: Only send reminders for claims submitted by providers within the last 6 months
    # This prevents historical claims from suddenly receiving emails when deployed to production
    CUTOFF_PERIOD = 6.months

    queue_as :user_data

    def perform
      Rails.logger.info "PractitionerReminderEmailJob sending reminder emails..."

      REMINDER_INTERVALS.each do |reminder_number, interval|
        batch_for_interval(reminder_number, interval).each do |claim|
          # Update count BEFORE sending to prevent duplicates if job fails
          claim.eligibility.update!(
            practitioner_reminder_email_sent_count: reminder_number,
            practitioner_reminder_email_last_sent_at: DateTime.current
          )

          claim.notes.create!(
            label: "practitioner_reminder",
            body: "Reminder #{reminder_number} email sent to practitioner #{claim.practitioner_email_address}"
          )

          EarlyYearsPaymentsMailer
            .with(claim: claim)
            .practitioner_claim_reminder
            .deliver_later
        end
      end
    end

    private

    def batch_for_interval(reminder_number, interval)
      # Explicit guard against attempting to send more than 3 reminders
      return Claim.none if reminder_number > 3

      base_query = Claim
        .joins("INNER JOIN early_years_payment_eligibilities ON early_years_payment_eligibilities.id = claims.eligibility_id AND claims.eligibility_type = 'Policies::EarlyYearsPayments::Eligibility'")
        .joins("LEFT OUTER JOIN decisions ON decisions.claim_id = claims.id AND decisions.undone = false")
        .where(policy: Policies::EarlyYearsPayments)
        .where(submitted_at: nil)
        .where(held: false) # Move held check to SQL
        .where.not(practitioner_email_address: [nil, ""])
        .where(early_years_payment_eligibilities: {
          practitioner_reminder_email_sent_count: reminder_number - 1
        })
        # Safeguard: Only send reminders for recent claims
        .where("early_years_payment_eligibilities.provider_claim_submitted_at > ?", CUTOFF_PERIOD.ago)
        # Move rejected check to SQL: exclude claims with rejected decisions
        .where("decisions.id IS NULL OR decisions.approved = true OR decisions.approved IS NULL")

      if reminder_number == 1
        # First reminder: 1 week after provider submission
        base_query
          .where(early_years_payment_eligibilities: {provider_claim_submitted_at: ..interval.ago})
          .where(early_years_payment_eligibilities: {practitioner_reminder_email_last_sent_at: nil})
      else
        # Subsequent reminders: based on last sent time
        base_query
          .where(early_years_payment_eligibilities: {practitioner_reminder_email_last_sent_at: ..interval.ago})
      end
    end
  end
end
