module Journeys
  module EarlyYearsTeachersFinancialIncentivePayments
    class EmploymentCheck
      Result = EmploymentChecks::Result

      def self.earliest_date_to_check
        2.months.ago.to_date
      end

      def initialize(setting:, hmrc_response_status:, hmrc_response_body:)
        @setting = setting
        @hmrc_response_status = hmrc_response_status
        @hmrc_response_body = hmrc_response_body
      end

      def passed?
        result.passed?
      end

      def result
        paye_check = EmploymentChecks::PayeReference.new(
          setting: setting,
          employments: employments
        )

        return paye_check.result if paye_check.usable?

        registered_person_check = EmploymentChecks::RegisteredPerson.new(
          setting: setting,
          employments: employments
        )

        return registered_person_check.result if registered_person_check.usable?

        EmploymentChecks::NamePostcode.new(
          setting: setting,
          employments: employments
        ).result
      end

      def employer_names
        employments.map { it.dig("employer", "name") }
      end

      private

      attr_reader :setting, :hmrc_response_status, :hmrc_response_body

      def employments
        @employments ||= employments_from_hmrc_response
      end

      def employments_from_hmrc_response
        return [] unless hmrc_response_status == 200

        body = JSON.parse(hmrc_response_body.to_s)
        return [] unless body.is_a?(Hash) && body["employments"].is_a?(Array)

        employments = body.fetch("employments")
        return [] unless employments.all? do |employment|
          employment.is_a?(Hash) &&
            employment["employer"].is_a?(Hash)
        end

        employments
      rescue JSON::ParserError
        []
      end
    end
  end
end
