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

      def self.earliest_eligible_contract_start_date
        # FIXME RL - waiting on policy to get back to us for what this should
        # be
      end
    end
  end
end
