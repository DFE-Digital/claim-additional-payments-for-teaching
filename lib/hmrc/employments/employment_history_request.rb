module Hmrc
  module Employments
    class EmploymentHistoryRequest
      def initialize(match_id:, from_date:, to_date: nil, paye_reference: nil)
        @match_id = match_id
        @from_date = from_date
        @to_date = to_date
        @paye_reference = paye_reference
      end

      def path
        params = [
          ["matchId", @match_id],
          ["fromDate", @from_date]
        ]

        params << ["toDate", @to_date] if @to_date.present?
        params << ["payeReference", @paye_reference] if @paye_reference.present?

        query_string = params.map do |key, value|
          "#{CGI.escape(key.to_s)}=#{CGI.escape(value.to_s)}"
        end.join("&")

        "/individuals/employments/paye?#{query_string}"
      end

      def headers(access_token:, correlation_id: nil)
        {
          "Authorization" => "Bearer #{access_token}",
          "Accept" => "application/vnd.hmrc.2.0+json",
          "CorrelationId" => correlation_id || SecureRandom.uuid
        }
      end

      def parse_response(body)
        JSON.parse(body)
      end
    end
  end
end
