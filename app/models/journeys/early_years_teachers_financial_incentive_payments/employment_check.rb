module Journeys
  module EarlyYearsTeachersFinancialIncentivePayments
    class EmploymentCheck
      def initialize(setting:, employments:)
        @setting = setting
        @employments = employments.map(&:deep_stringify_keys)
      end

      def passed?
        employments.last.fetch("employer").fetch("name") == setting.name
      end

      private

      attr_reader :setting, :employments
    end
  end
end
