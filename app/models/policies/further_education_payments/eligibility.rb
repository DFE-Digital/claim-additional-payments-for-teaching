module Policies
  module FurtherEducationPayments
    class Eligibility < ApplicationRecord
      self.table_name = "further_education_payments_eligibilities"

      has_one :claim, as: :eligibility, inverse_of: :eligibility

      belongs_to :possible_school, optional: true, class_name: "School"
      belongs_to :school, optional: true

      # Claim#school expects this
      alias_method :current_school, :school

      def policy
        Policies::FurtherEducationPayments
      end

      def ineligible?
        false
      end
    end
  end
end
