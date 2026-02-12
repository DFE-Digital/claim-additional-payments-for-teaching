module FurtherEducationPayments
  module Providers
    class OverdueChaserEmailJob < ApplicationJob
      def perform
        return unless FeatureFlag.enabled?("fe_provider_dashboard")

        base_scope = Policies::FurtherEducationPayments::Eligibility
          .awaiting_provider_verification_year_2
          .where(provider_verification_completed_at: nil)
          .where(provider_verification_deadline: Policies::FurtherEducationPayments::POST_SUBMISSION_VERIFICATION_DEADLINE.ago..Time.zone.now)

        scope = base_scope.where(
          provider_verification_chase_email_last_sent_at: ..1.week.ago
        ).or(
          base_scope.where(provider_verification_chase_email_last_sent_at: nil)
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
