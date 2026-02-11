module Policies
  module FurtherEducationPayments
    class ProviderFlag < ApplicationRecord
      self.table_name = "further_education_payments_provider_flags"

      attribute :academic_year, AcademicYear::Type.new

      enum :reason, %w[clawback].index_by(&:itself)

      validate :fe_provider_exists

      validates :academic_year, presence: true

      validates(
        :reason,
        inclusion: {
          in: -> { reasons.keys },
          messsage: "reason must be one of #{reasons.keys}"
        }
      )

      def self.for(fe_provider)
        find_by(
          academic_year: fe_provider.academic_year,
          ukprn: fe_provider.ukprn
        )
      end

      private

      def fe_provider_exists
        unless fe_provider_exists?
          errors.add(:ukprn, "provider with UKPRN #{ukprn} not found")
        end
      end

      def fe_provider_exists?
        EligibleFeProvider.exists?(academic_year: academic_year, ukprn: ukprn)
      end
    end
  end
end
