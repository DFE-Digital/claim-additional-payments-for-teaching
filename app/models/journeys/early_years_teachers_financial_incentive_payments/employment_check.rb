module Journeys
  module EarlyYearsTeachersFinancialIncentivePayments
    class EmploymentCheck
      def initialize(setting:, employments:)
        @setting = setting
        @employments = employments
          .map(&:deep_stringify_keys)
          .map(&Employment.method(:new))
      end

      def passed?
        return false if employments.none?

        employments.select(&:active?).map(&:employer_name).any? do |employer_name|
          setting.name == employer_name
        end
      end

      private

      attr_reader :setting, :employments

      class Employment
        def initialize(hash)
          @hash = hash
        end

        def employer_name
          @hash.fetch("employer").fetch("name")
        end

        def active?
          end_date.blank?
        end

        def start_date
          Date.parse(@hash.fetch("startDate"))
        end

        def end_date
          @hash.fetch("endDate", nil)
        end

        def invalid?
          !valid?
        end

        def valid?
          return false unless @hash.is_a?(Hash)

          employer_name
          start_date

          true
        rescue KeyError, Date::Error
          false
        end
      end
    end
  end
end
