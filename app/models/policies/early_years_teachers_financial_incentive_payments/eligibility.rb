module Policies
  module EarlyYearsTeachersFinancialIncentivePayments
    class Eligibility < ApplicationRecord
      self.table_name = "early_years_teachers_financial_incentive_payments_eligibilities"

      has_one :claim, as: :eligibility, inverse_of: :eligibility
      has_many_attached :employment_proofs

      # does nothing, simply here for duck typing compatability
      attr_accessor :teacher_reference_number

      AMENDABLE_ATTRIBUTES = []

      def policy
        Policies::EarlyYearsTeachersFinancialIncentivePayments
      end

      def eligible_eytfi_provider
        EligibleEytfiProvider
          .by_academic_year(claim.academic_year)
          .find_by!(urn: eligible_eytfi_provider_urn)
      end
    end
  end
end
