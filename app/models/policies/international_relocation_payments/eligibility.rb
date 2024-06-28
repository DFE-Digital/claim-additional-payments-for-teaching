module Policies
  module InternationalRelocationPayments
    class Eligibility < ApplicationRecord
      self.table_name = "international_relocation_payments_eligibilities"

      PRE_ACADEMIC_YEAR_WINDOW_LIMIT = 6.months

      def self.earliest_eligible_contract_start_date
        Journeys::GetATeacherRelocationPayment
          .configuration
          .current_academic_year
          .start_of_autumn_term - PRE_ACADEMIC_YEAR_WINDOW_LIMIT
      end

      has_one :claim, as: :eligibility, inverse_of: :eligibility

      def ineligible?
        false
      end

      def policy
        Policies::InternationalRelocationPayments
      end
    end
  end
end
