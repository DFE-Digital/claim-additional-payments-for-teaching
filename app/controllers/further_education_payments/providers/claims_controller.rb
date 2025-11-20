module FurtherEducationPayments
  module Providers
    class ClaimsController < BaseController
      def index
        @claims = current_provider.claims.unverified.by_academic_year(
          Journeys::FurtherEducationPayments.configuration.current_academic_year
        ).order(:created_at)

        @unverified_count = @claims.count

        @not_started_count = @claims.verification_not_started.count

        @not_started_overdue_count = @claims.verification_not_started.verification_overdue.count

        @in_progress_count = @claims.verification_in_progress.count

        @in_progress_overdue_count = @claims.verification_in_progress.verification_overdue.count
      end
    end
  end
end
