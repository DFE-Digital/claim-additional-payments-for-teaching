module Policies
  module InternationalRelocationPayments
    class Eligibility < ApplicationRecord
      self.table_name = "international_relocation_payments_eligibilities"

      AMENDABLE_ATTRIBUTES = %i[].freeze

      has_one :claim, as: :eligibility, inverse_of: :eligibility
      belongs_to :current_school, class_name: "School"

      attr_accessor :teacher_reference_number

      attribute :employment_histories, EmploymentHistoriesType.new

      def ineligible?
        false
      end

      def policy
        Policies::InternationalRelocationPayments
      end

      def school
        current_school
      end
    end
  end
end
