module Policies
  module FurtherEducationPayments
    class Eligibility < ApplicationRecord
      self.table_name = "further_education_payments_eligibilities"

      has_one :claim, as: :eligibility, inverse_of: :eligibility

      def policy
        Policies::FurtherEducationPayments
      end

      def ineligible?
        false
      end
    end
  end
end
