module Policies
  module EarlyYearsPayment
    class Eligibility < ApplicationRecord
      self.table_name = "early_years_payment_eligibilities"

      has_one :claim, as: :eligibility, inverse_of: :eligibility

      def policy
        Policies::EarlyYearsPayment
      end

      def ineligible?
        false
      end
    end
  end
end
