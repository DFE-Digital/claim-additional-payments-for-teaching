module Policies
  module InternationalRelocationPayments
    class Eligibility < ApplicationRecord
      self.table_name = "international_relocation_payments_eligibilities"

      AMENDABLE_ATTRIBUTES = %i[].freeze

      has_one :claim, as: :eligibility, inverse_of: :eligibility

      attr_accessor :teacher_reference_number

      def award_amount
        0
      end

      # No current_school attribute on the model. This method is for compatibility with the admin UI.
      def current_school
        nil
      end

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
