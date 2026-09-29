module Hmrc
  module Employments
    class MatchingRequest
      def initialize(first_name:, last_name:, nino:, date_of_birth:)
        @first_name = first_name
        @last_name = last_name
        @nino = nino
        @date_of_birth = date_of_birth
      end

      def path
        "/individuals/matching/"
      end

      def payload
        {
          firstName: @first_name,
          lastName: @last_name,
          nino: @nino,
          dateOfBirth: @date_of_birth
        }.to_json
      end

      def headers(access_token:, correlation_id: nil)
        {
          "Authorization" => "Bearer #{access_token}",
          "Accept" => "application/vnd.hmrc.2.0+json",
          "CorrelationId" => correlation_id || SecureRandom.uuid,
          "Content-Type" => "application/json"
        }
      end

      def match_id_from_response(body)
        href = JSON.parse(body).dig("_links", "individual", "href")
        href.split("/").last
      end
    end
  end
end
