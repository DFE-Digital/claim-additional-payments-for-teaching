module FurtherEducationPayments
  module Providers
    class ClaimsController < BaseController
      def index
        @claims = current_provider.unverified_claims.by_academic_year(
          Journeys::FurtherEducationPayments.configuration.current_academic_year
        ).order(:created_at)

        @unverified_count = current_provider.unverified_claims.by_academic_year(
          Journeys::FurtherEducationPayments.configuration.current_academic_year
        ).count

        @not_started_count = current_provider.claims_not_started_verification.by_academic_year(
          Journeys::FurtherEducationPayments.configuration.current_academic_year
        ).count

        @not_started_overdue_count = current_provider.claims_not_started_and_overdue_verification.by_academic_year(
          Journeys::FurtherEducationPayments.configuration.current_academic_year
        ).count

        @in_progress_count = current_provider.claims_in_progress.by_academic_year(
          Journeys::FurtherEducationPayments.configuration.current_academic_year
        ).count

        @in_progress_overdue_count = current_provider.claims_in_progress_and_overdue_verification.by_academic_year(
          Journeys::FurtherEducationPayments.configuration.current_academic_year
        ).count
      end
    end
  end
end
