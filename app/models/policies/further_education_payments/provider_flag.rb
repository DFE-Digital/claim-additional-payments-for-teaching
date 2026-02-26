module Policies
  module FurtherEducationPayments
    class ProviderFlag < ApplicationRecord
      self.table_name = "further_education_payments_provider_flags"

      enum :reason, %w[clawback].index_by(&:itself)

      validate :fe_provider_exists

      validates(
        :reason,
        inclusion: {
          in: -> { reasons.keys },
          messsage: "reason must be one of #{reasons.keys.join(", ")}"
        }
      )

      def self.for(fe_provider)
        find_by(ukprn: fe_provider.ukprn)
      end

      private

      def fe_provider_exists
        unless fe_provider_exists?
          errors.add(:ukprn, "provider with UKPRN #{ukprn} not found")
        end
      end

      def fe_provider_exists?
        EligibleFeProvider.exists?(ukprn: ukprn)
      end
    end
  end
end
