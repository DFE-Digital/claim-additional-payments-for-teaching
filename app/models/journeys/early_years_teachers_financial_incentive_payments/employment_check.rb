module Journeys
  module EarlyYearsTeachersFinancialIncentivePayments
    class EmploymentCheck
      def self.earliest_date_to_check
        1.month.ago.to_date
      end

      def initialize(setting:, employments:)
        @setting = setting
        @employments = employments.map(&:deep_stringify_keys)
      end

      def passed?
        return false if employments.none?

        employments
          .map { it.dig("employer", "name") }
          .any? { |employer_name| setting.name == employer_name }
      end

      private

      attr_reader :setting, :employments
    end
  end
end
