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

      def practitioner_name
        [practitioner_first_name, practitioner_surname].join(" ")
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
