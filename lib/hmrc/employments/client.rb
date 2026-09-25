module Hmrc
  module Employments
    class Client < Hmrc::BaseClient
      def initialize(
        base_url: Employments.configuration.base_url,
        client_id: Employments.configuration.client_id,
        client_secret: Employments.configuration.client_secret,
        totp_secret: Employments.configuration.totp_secret,
        http_client: Employments.configuration.http_client,
        logger: Employments.configuration.logger
      )
        super(
          base_url: base_url,
          client_id: client_id,
          client_secret: client_secret,
          http_client: http_client,
          logger: logger
        )
        self.totp_secret = totp_secret
      end

      def employment_history(match_id:, from_date:, to_date: nil, paye_reference: nil, correlation_id: nil, timeout: nil)
        request = EmploymentHistoryRequest.new(
          match_id: match_id,
          from_date: from_date,
          to_date: to_date,
          paye_reference: paye_reference
        )

        get_request!(
          request.path,
          request.headers(access_token: access_token(timeout: timeout), correlation_id: correlation_id),
          timeout: timeout
        )
      rescue Hmrc::ResponseError => e
        raise Hmrc::Employments::ResponseError.new(e.response)
      end

      def employment_history_for_individual(first_name:, last_name:, nino:, date_of_birth:, from_date: nil, to_date: nil, paye_reference: nil, correlation_id: nil, timeout: nil)
        request = MatchingRequest.new(
          first_name: first_name,
          last_name: last_name,
          nino: nino,
          date_of_birth: date_of_birth
        )

        matching_response = post_request!(
          request.path,
          request.payload,
          request.headers(access_token: access_token(timeout: timeout), correlation_id: correlation_id),
          timeout: timeout
        )

        match_id = request.match_id_from_response(matching_response.body)
        return nil if match_id.nil?

        employment_history(
          match_id: match_id,
          from_date: from_date,
          to_date: to_date,
          paye_reference: paye_reference,
          correlation_id: correlation_id,
          timeout: timeout
        )
      rescue Hmrc::ResponseError => e
        raise Hmrc::Employments::ResponseError.new(e.response) unless no_match_response?(e.response)

        nil
      end

      private

      def access_token(timeout: nil)
        if @access_token.nil? || token_expired?
          response = post_request!(
            "/oauth/token",
            oauth_token_request_payload,
            oauth_request_headers,
            timeout: timeout
          )

          body = JSON.parse(response.body)
          @access_token = body.fetch("access_token")
          @access_token_expiry = Time.current + body.fetch("expires_in").to_i
        end

        @access_token
      end

      def no_match_response?(response)
        return false if response.nil?

        return false unless response.respond_to?(:status) && response.status == 404

        body = response.respond_to?(:body) ? response.body : nil
        return false if body.nil?

        parsed = JSON.parse(body)
        parsed.is_a?(Hash) && parsed["code"] == "MATCHING_FAILED"
      rescue JSON::ParserError
        false
      end

      attr_accessor :base_url, :client_id, :client_secret, :totp_secret, :http_client, :logger, :token, :token_expiry

      def token_expired?
        return true if @access_token_expiry.nil?

        @access_token_expiry <= Time.current
      end

      def oauth_token_request_payload
        {
          grant_type: "client_credentials",
          client_id: client_id,
          client_secret: oauth_client_secret
        }
      end

      def oauth_request_headers
        {
          "Accept" => "application/json",
          "Content-Type" => "application/x-www-form-urlencoded",
          "User-Agent" => "dfe-claim-additional-payments"
        }
      end

      def oauth_client_secret
        return client_secret unless totp_secret.present?

        totp = ROTP::TOTP.new(
          totp_secret,
          digits: 8,
          digest: "sha512",
          interval: 30
        )

        "#{totp.at(Time.current)}#{client_secret}"
      end
    end
  end
end
