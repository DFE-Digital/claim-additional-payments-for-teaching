module Journeys
  module EarlyYearsTeachersFinancialIncentivePayments
    class EmploymentCheck
      SIMILARITY_THRESHOLD = 2.0 / 3.0
      IGNORED_WORDS = %w[
        ltd
        limited
        private
        nursery
        day
        preschool
      ].join("|")

      def self.earliest_date_to_check
        2.months.ago.to_date
      end

      def initialize(setting:, hmrc_response_status:, hmrc_response_body:)
        @setting = setting
        @hmrc_response_status = hmrc_response_status
        @hmrc_response_body = hmrc_response_body
      end

      def passed?
        employments.any? do |employment|
          setting_employer?(employment.fetch("employer"))
        end
      end

      def employer_names
        employments.map { it.dig("employer", "name") }
      end

      private

      attr_reader :setting, :hmrc_response_status, :hmrc_response_body

      def setting_employer?(employer)
        address = employer.fetch("address", {})
        postcode = address.fetch("postcode", nil)
        employer_name = employer.fetch("name", nil)

        return false unless postcode.present?
        return false unless employer_name.present?

        # If postcodes don't match we can't rely on name checking as they could
        # be two separate nurseries with the same name
        return false unless clean_postcode(postcode) == clean_postcode(setting.postcode)

        similarity(
          clean_company_name(employer_name).split,
          clean_company_name(setting.name).split
        ) >= SIMILARITY_THRESHOLD
      end

      def similarity(words_1, words_2)
        return 0.0 if words_1.empty? || words_2.empty?

        m = words_1.length
        n = words_2.length

        # Build a table where dp[i][j] represents the length of the
        # longest common subsequence between:
        #
        #   - The first i words of words_1
        #   - The first j words of words_2
        #
        # We need an extra row and column to represent empty sequences.
        # These are initialised to zero, since an empty sequence cannot
        # have any matching words.
        dp = Array.new(m + 1) { Array.new(n + 1, 0) }

        # Compare every word in words_1 against every word in words_2.
        #
        # We start at 1 because row 0 and column 0 represent empty sequences.
        (1..m).each do |i|
          (1..n).each do |j|
            dp[i][j] = if words_1[i - 1] == words_2[j - 1]
              # The words match!
              #
              # Extend the longest common subsequence found before these
              # two words by one.
              #
              # dp[i - 1][j - 1] is the result for both sequences
              # excluding their current words.
              dp[i - 1][j - 1] + 1
            else
              # The words don't match.
              #
              # Try skipping the current word from either sequence:
              #
              # dp[i - 1][j] - Skip the current word in words_1
              # dp[i][j - 1] - Skip the current word in words_2
              #
              # Keep whichever gives us the longest subsequence.
              [dp[i - 1][j], dp[i][j - 1]].max
            end
          end
        end

        # The bottom-right cell contains the length of the longest
        # common subsequence across both complete arrays.
        lcs_length = dp[m][n]

        # Normalise the result to a similarity score between 0 and 1.
        #
        # Using the sum of both lengths ensures:
        # - Identical arrays score 1.0
        # - Arrays with no matching words score 0.0
        # - Extra/missing words reduce the score proportionally
        2.0 * lcs_length / (m + n)
      end

      def clean_text(value)
        value
          .to_s
          .downcase
          .strip
          .remove(",")
          .remove(",")
          .remove("-")
          .remove("'")
          .remove("’")
          .squish
      end

      def clean_postcode(value)
        clean_text(value).gsub(/\s+/, "")
      end

      def clean_company_name(name)
        clean_text(name)
          .gsub(/\b(?:#{IGNORED_WORDS})\b\.?/o, "")
          .gsub("@", "at")
          .gsub("&", "and")
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
