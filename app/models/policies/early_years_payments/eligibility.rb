module Policies
  module EarlyYearsPayments
    class Eligibility < ApplicationRecord
      AMENDABLE_ATTRIBUTES = [].freeze

      self.table_name = "early_years_payment_eligibilities"

      has_one :claim, as: :eligibility, inverse_of: :eligibility

      # does nothing, simply here for duck typing compatability
      attr_accessor :teacher_reference_number

      def policy
        Policies::EarlyYearsPayments
      end

      def ineligible?
        false
      end

      def eligible_ey_provider
        EligibleEyProvider.find_by_urn(nursery_urn)
      end

      def provider_claim_submitted?
        provider_claim_submitted_at.present?
      end

      def employment_task_available_at
        start_date + 6.months
      end

      def employment_task_available?
        Date.today >= employment_task_available_at
      end
    end
  end
end
