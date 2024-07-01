module Policies
  module InternationalRelocationPayments
    class Eligibility < ApplicationRecord
      self.table_name = "international_relocation_payments_eligibilities"

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
