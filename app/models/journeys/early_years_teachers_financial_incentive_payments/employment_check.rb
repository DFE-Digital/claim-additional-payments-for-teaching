module Journeys
  module EarlyYearsTeachersFinancialIncentivePayments
    class EmploymentCheck
      PASSING_SCORE = 100
      ADDRESS_SCORES = {
        town: ["line4", 25],
        address_line_3: ["line3", 10],
        address_line_2: ["line2", 8],
        address_line_1: ["line1", 5]
      }.freeze

      def self.earliest_date_to_check
        1.month.ago.to_date
      end

      def initialize(setting:, hmrc_response_status:, hmrc_response_body:)
        @setting = setting
        @hmrc_response_status = hmrc_response_status
        @hmrc_response_body = hmrc_response_body
      end

      def passed?
        employments.any? do |employment|
          match_score(employment.fetch("employer")) >= PASSING_SCORE
        end
      end

      def employer_names
        employments.map { it.dig("employer", "name") }
      end

      private

      attr_reader :setting, :hmrc_response_status, :hmrc_response_body

      def match_score(employer)
        score = name_score(employer.fetch("name"))
        return 0 if score.zero?

        address = employer["address"]
        return score unless address.is_a?(Hash)

        postcode = clean_postcode(address["postcode"])
        score += 50 if postcode.present? && postcode == clean_postcode(setting.postcode)

        ADDRESS_SCORES.each do |part, (line, points)|
          score += points if partial_text_match?(address[line], setting.public_send(part))
        end

        score
      end

      def name_score(employer_name)
        setting_name = clean_company_name(setting.name)
        employer_name = clean_company_name(employer_name)

        return 0 if setting_name.empty? || employer_name.empty?
        return 100 if setting_name == employer_name

        setting_first_word = setting_name.split(" ").first
        employer_first_word = employer_name.split(" ").first

        employer_name_match_setting = employer_name.include?(setting_first_word)
        setting_name_match_employer = setting_name.include?(employer_first_word)

        if employer_name_match_setting || setting_name_match_employer
          50
        else
          0
        end
      end

      def partial_text_match?(first, second)
        first = clean_text(first)
        second = clean_text(second)
        first.present? && second.present? && (first.include?(second) || second.include?(first))
      end

      def clean_text(value)
        value.is_a?(String) ? value.downcase.strip.delete(",.-") : ""
      end

      def clean_postcode(value)
        clean_text(value).gsub(/\s+/, "")
      end

      def clean_company_name(name)
        name
          .to_s
          .downcase
          .remove("ltd.")
          .remove("ltd")
          .remove("limited")
          .squish
      end

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
