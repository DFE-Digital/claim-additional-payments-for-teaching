module EarlyYearsPayments
  class ProviderSixMonthEmploymentReminderJob < ApplicationJob
    queue_as :user_data

    def perform
      year_two_claims = Claim
        .by_academic_year(AcademicYear.new("2025/2026"))
        .where.not(id: Claim.rejected.or(Claim.approved).select(:id))

      Policies::EarlyYearsPayments::Eligibility
        .where(start_date: ..6.months.ago.beginning_of_day)
        .where(provider_six_month_employment_reminder_sent_at: nil)
        .joins(:claim)
        .merge(year_two_claims)
        .includes(:claim)
        .find_each do |eligibility|
          EarlyYearsPaymentsMailer
            .with(claim: eligibility.claim)
            .provider_six_month_employment_reminder
            .deliver_later

          eligibility.update!(
            provider_six_month_employment_reminder_sent_at: DateTime.current
          )
        end
    end
  end
end
