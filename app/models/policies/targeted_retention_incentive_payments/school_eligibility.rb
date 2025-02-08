module Policies
  module TargetedRetentionIncentivePayments
    # Checks if a school is eligible for Targeted Retention Incentive. A school being
    # eligible is necessary but not sufficient for an Targeted Retention Incentive award to be made.
    #
    # Whether a school is eligible for Targeted Retention Incentive could be checked via a new database
    # column on `School`.
    class SchoolEligibility
      def initialize(school)
        raise "nil school" if school.nil?

        @school = school
      end

      def eligible?
        @school.targeted_retention_incentive_payments_awards.where(academic_year: current_academic_year.to_s).any?
      end

      private

      def current_academic_year
        Journeys.for_policy(TargetedRetentionIncentivePayments).configuration.current_academic_year
      end
    end
  end
end
