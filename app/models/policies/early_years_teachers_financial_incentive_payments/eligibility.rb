module Policies
  module EarlyYearsTeachersFinancialIncentivePayments
    class Eligibility < ApplicationRecord
      self.table_name = "early_years_teachers_financial_incentive_payments_eligibilities"

      has_one :claim, as: :eligibility, inverse_of: :eligibility

      # does nothing, simply here for duck typing compatability
      attr_accessor :teacher_reference_number

      AMENDABLE_ATTRIBUTES = []

      def policy
        Policies::EarlyYearsTeachersFinancialIncentivePayments
      end
    end
  end
end
