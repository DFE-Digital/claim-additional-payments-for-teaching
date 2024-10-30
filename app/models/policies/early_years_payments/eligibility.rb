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

      def provider_claim_submitted?
        provider_claim_submitted_at.present?
      end

      def practitioner_entered_full_name
        "#{practitioner_first_name} #{practitioner_surname}"
      end

      def practitioner_and_provider_entered_names_match?
        practitioner_first_name.downcase == claim.onelogin_idv_first_name.downcase &&
          practitioner_surname.downcase == claim.onelogin_idv_last_name.downcase
      end

      def practitioner_and_provider_entered_names_partial_match?
        practitioner_first_name.downcase == claim.onelogin_idv_first_name.downcase ||
          practitioner_surname.downcase == claim.onelogin_idv_last_name.downcase
      end

      def practitioner_journey_completed?
        claim.submitted_at.present?
      end
    end
  end
end
