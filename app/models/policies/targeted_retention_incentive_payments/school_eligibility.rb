module Policies
  module TargetedRetentionIncentivePayments
    # Checks if a school is eligible for LUP. A school being
    # eligible is necessary but not sufficient for an LUP award to be made.
    #
    # Whether a school is eligible for LUP could be checked via a new database
    # column on `School`.
    class SchoolEligibility
      def initialize(school)
        raise "nil school" if school.nil?

        @school = school
      end

      def eligible?
        @school.targeted_retention_incentive_payments_awards
          .by_academic_year(current_academic_year)
          .any?
      end

      private

      def current_academic_year
        TargetedRetentionIncentivePayments.current_academic_year
      end
    end
  end
end
