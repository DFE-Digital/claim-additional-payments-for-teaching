module FurtherEducationPayments
  module Providers
    class ClaimsController < BaseController
      def index
        @claims = claim_scope.order(:created_at)

        @unverified_count = claim_scope.count

        @not_started_count = not_started.count
        @not_started_overdue_count = not_started.count do |claim|
          Policies::FurtherEducationPayments.verification_overdue?(claim)
        end

        @in_progress_count = in_progress.count
        @in_progress_overdue_count = in_progress.count do |claim|
          Policies::FurtherEducationPayments.verification_overdue?(claim)
        end
      end

      private

      def claim_scope
        super
          .where(id: Claim.fe_provider_unverified.select(:id))
          .joins(
            <<~SQL
              INNER JOIN further_education_payments_eligibilities
              ON further_education_payments_eligibilities.id = claims.eligibility_id
            SQL
          )
      end

      def not_started
        @not_started ||= claim_scope
          .select(:created_at)
          .where(further_education_payments_eligibilities: {provider_verification_started_at: nil})
          .to_a
      end

      def in_progress
        @in_progress ||= claim_scope
          .select(:created_at)
          .where.not(further_education_payments_eligibilities: {provider_verification_started_at: nil})
          .to_a
      end
    end
  end
end
