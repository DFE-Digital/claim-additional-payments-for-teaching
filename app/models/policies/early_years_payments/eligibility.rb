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
    end
  end
end
