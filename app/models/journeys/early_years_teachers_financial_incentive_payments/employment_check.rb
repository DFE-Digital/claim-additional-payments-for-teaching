module Journeys
  module EarlyYearsTeachersFinancialIncentivePayments
    class EmploymentCheck
      def self.earliest_date_to_check
        1.month.ago.to_date
      end

      def initialize(setting:, hmrc_response_status:, hmrc_response_body:)
        @setting = setting
        @hmrc_response_status = hmrc_response_status
        @hmrc_response_body = hmrc_response_body
      end

      def passed?
        return false if employments.none?

        employer_names.any? { |employer_name| setting.name == employer_name }
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
            employment["employer"].is_a?(Hash) &&
            employment["employer"]["name"].is_a?(String) &&
            employment["employer"]["name"].present?
        end

        employments
      rescue JSON::ParserError
        []
      end
    end
  end
end
