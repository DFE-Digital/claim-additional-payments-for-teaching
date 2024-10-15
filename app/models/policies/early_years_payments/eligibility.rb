module Policies
  module EarlyYearsPayments
    class Eligibility < ApplicationRecord
      self.table_name = "early_years_payment_eligibilities"

      has_one :claim, as: :eligibility, inverse_of: :eligibility

      def policy
        Policies::EarlyYearsPayments
      end

      def ineligible?
        false
      end

      def eligible_ey_provider
        EligibleEyProvider.find_by_urn(nursery_urn)
      end

      def practitioner_claim_submitted?
        practitioner_claim_submitted_at.present?
      end
    end
  end
end
