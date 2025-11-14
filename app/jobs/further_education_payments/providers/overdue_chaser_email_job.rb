module FurtherEducationPayments
  module Providers
    class OverdueChaserEmailJob < ApplicationJob
      def perform
        scope = Policies::FurtherEducationPayments::Eligibility

        scope = scope.awaiting_provider_verification_year_2

        scope = scope.where(provider_verification_completed_at: nil)

        # Verification is due 2 weeks after claim creation
        overdue_date = 2.weeks.ago

        # Claims after this date will have received 3 chaser emails
        received_3_chasers_date = 5.weeks.ago + 1.day

        # Overdue claims that haven't received 3 chasers
        target_date_range = received_3_chasers_date.beginning_of_day..overdue_date.end_of_day

        scope = scope.joins(:claim).merge(
          Claim.where(created_at: target_date_range)
        )

        scope = scope.where(
          provider_verification_chase_email_last_sent_at: ..1.week.ago
        ).or(
          scope.where(provider_verification_chase_email_last_sent_at: nil)
        )

        scope.find_each do |eligibility|
          FurtherEducationPaymentsMailer
            .with(eligibility: eligibility)
            .provider_verification_overdue_chaser_email
            .deliver_later

          eligibility.update!(
            provider_verification_chase_email_last_sent_at: Time.current
          )
        end
      end
    end
  end
end
