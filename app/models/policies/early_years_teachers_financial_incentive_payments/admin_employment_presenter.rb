module Policies
  module EarlyYearsTeachersFinancialIncentivePayments
    class AdminEmploymentPresenter
      def initialize(eligibility)
        @eligibility = eligibility
      end

      def message
        if eligibility.hmrc_response_status.nil?
          "The HMRC employment check has not been completed."
        elsif eligibility.hmrc_employment_check_not_found?
          "Claimant not found on HMRC."
        elsif eligibility.hmrc_response_status != 200
          "Unable to retrieve employment records due to an HMRC error."
        elsif employments.nil?
          "The employment response from HMRC could not be read."
        elsif employments.empty?
          "HMRC returned no employment records for this claimant."
        end
      end

      def employment_summaries
        return [] if message.present?

        employments.map(&:summary_rows)
      end

      private

      attr_reader :eligibility

      def employments
        return @employments if defined?(@employments)

        @employments = parse_employments
      end

      def parse_employments
        body = JSON.parse(eligibility.hmrc_response_body.to_s)
        return unless body.is_a?(Hash) && body["employments"].is_a?(Array)

        employments = body.fetch("employments")

        return unless employments.all? do |employment|
          employment_response_valid?(employment)
        end

        employments.map(&Employment.method(:new))
      rescue JSON::ParserError
        nil
      end

      def employment_response_valid?(employment)
        return false unless employment.is_a?(Hash)
        return false unless employment["employer"].is_a?(Hash)

        employment["employer"]["address"].nil? ||
          employment["employer"]["address"].is_a?(Hash)
      end

      class Employment
        def initialize(data)
          @data = data
          @employer = data.fetch("employer")
        end

        def summary_rows
          rows = [["Employer name", name]]

          address.each do |line, value|
            line = line.underscore.gsub(/(\D)(\d)/, '\1 \2').humanize.downcase
            label = "Address #{line}"
            rows << [label, value]
          end

          rows << ["Employment start date", start_date]
          rows << ["Employment end date", end_date]
          rows
        end

        private

        def name
          @employer.fetch("name", "Not returned")
        end

        def address
          @employer.fetch("address", {}).transform_values do |line|
            line.presence || "Not returned"
          end
        end

        def start_date
          @data.fetch("startDate", "Not returned")
        end

        def end_date
          @data.fetch("endDate", "Not returned")
        end
      end
    end
  end
end
