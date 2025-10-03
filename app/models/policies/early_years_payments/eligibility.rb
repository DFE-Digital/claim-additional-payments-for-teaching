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
        EligibleEyProvider
          .unscoped
          .order(created_at: :desc)
          .find_by(urn: nursery_urn)
      end

      def provider_claim_submitted?
        provider_claim_submitted_at.present?
      end

      def employment_task_available_at
        start_date + RETENTION_PERIOD
      end

      alias_method :employment_check_date, :employment_task_available_at

      def employment_task_available?
        Date.today >= employment_task_available_at
      end

      # This is the practioner name that the provider entered
      def practitioner_name
        [practitioner_first_name, practitioner_surname].join(" ")
      end

      def practitioner_and_provider_entered_names_match?
        first_names_match? && surnames_match?
      end

      def practitioner_and_provider_entered_names_partial_match?
        first_names_match? || surnames_match?
      end

      def practitioner_journey_completed?
        claim.submitted_at.present?
      end

      def alternative_idv_completed?
        alternative_idv_completed_at.present?
      end

      private

      def first_names_match?
        practitioner_first_name.downcase.strip ==
          claim.onelogin_idv_first_name.downcase.strip
      end

      def surnames_match?
        practitioner_surname.downcase.strip ==
          claim.onelogin_idv_last_name.downcase.strip
      end
    end
  end
end
