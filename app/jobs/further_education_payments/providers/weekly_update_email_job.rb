module FurtherEducationPayments
  module Providers
    class WeeklyUpdateEmailJob < ApplicationJob
      def perform
        providers_with_unverified_claims =
          Policies::FurtherEducationPayments::EligibleFeProvider.joins(
            "JOIN schools ON " \
            "schools.ukprn::integer = eligible_fe_providers.ukprn::integer"
          ).joins(
            "JOIN further_education_payments_eligibilities " \
            "ON further_education_payments_eligibilities.school_id = schools.id"
          ).merge(
            Policies::FurtherEducationPayments::Eligibility
              .awaiting_provider_verification_year_2
          ).distinct

        providers_with_unverified_claims.each do |provider|
          FurtherEducationPaymentsMailer
            .with(provider: provider)
            .provider_weekly_update_email
            .deliver_later
        end
      end
    end
  end
end
