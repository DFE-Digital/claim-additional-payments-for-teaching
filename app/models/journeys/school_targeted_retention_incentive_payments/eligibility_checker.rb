module Journeys
  module SchoolTargetedRetentionIncentivePayments
    class EligibilityChecker
      attr_reader :journey_session

      delegate_missing_to :answers

      def initialize(journey_session:)
        @journey_session = journey_session
      end

      def ineligible?
        ineligibility_reason.present?
      end

      def ineligibility_reason
        return :school_ineligible if indicated_ineligible_school?
        :at_least_half_contracted_hours if not_at_least_half_contracted_hours?
      end

      private

      def answers
        journey_session.answers
      end

      def indicated_ineligible_school?
        current_school.present? && !school_eligibility_class.new(current_school).eligible?
      end

      def school_eligibility_class
        Policies::TargetedRetentionIncentivePayments::SchoolEligibility
      end

      def not_at_least_half_contracted_hours?
        !answers.half_contracted_hours.nil? && answers.half_contracted_hours == false
      end
    end
  end
end
