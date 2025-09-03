module EarlyYearsPayments
  class PractitionerReminderEmailJob < ApplicationJob
    REMINDER_INTERVALS = {
      1 => 1.week,
      2 => 2.weeks,
      3 => 4.weeks
    }.freeze

    queue_as :user_data

    def perform
      Rails.logger.info "PractitionerReminderEmailJob sending reminder emails..."

      REMINDER_INTERVALS.each do |reminder_number, interval|
        batch_for_interval(reminder_number, interval).each do |claim|
          claim.notes.create!(
            label: "practitioner_reminder",
            body: "Reminder #{reminder_number} email sent to practitioner #{claim.practitioner_email_address}"
          )

          EarlyYearsPaymentsMailer
            .with(claim: claim)
            .practitioner_claim_reminder
            .deliver_later

          claim.eligibility.update!(
            practitioner_reminder_email_sent_count: reminder_number,
            practitioner_reminder_email_last_sent_at: DateTime.current
          )
        end
      end
    end

    private

    def batch_for_interval(reminder_number, interval)
      base_query = Claim
        .joins("INNER JOIN early_years_payment_eligibilities ON early_years_payment_eligibilities.id = claims.eligibility_id AND claims.eligibility_type = 'Policies::EarlyYearsPayments::Eligibility'")
        .where(policy: Policies::EarlyYearsPayments)
        .where(submitted_at: nil)
        .where.not(practitioner_email_address: [nil, ""])
        .where(early_years_payment_eligibilities: {
          practitioner_reminder_email_sent_count: reminder_number - 1
        })

      query = if reminder_number == 1
        # First reminder: 1 week after provider submission
        base_query
          .where(early_years_payment_eligibilities: {provider_claim_submitted_at: ..interval.ago})
          .where(early_years_payment_eligibilities: {practitioner_reminder_email_last_sent_at: nil})
      else
        # Subsequent reminders: based on last sent time
        base_query
          .where(early_years_payment_eligibilities: {practitioner_reminder_email_last_sent_at: ..interval.ago})
      end

      # Preload the eligibility to avoid N+1 queries
      query
        .includes(:eligibility, :decisions)
        .reject { |claim| claim.held? || claim.latest_decision&.rejected? }
    end
  end
end
