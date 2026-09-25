module Hmrc
  module BankValidations
    class Client < Hmrc::BaseClient
      def initialize(
        base_url: Hmrc::BankValidations.configuration.base_url,
        client_id: Hmrc::BankValidations.configuration.client_id,
        client_secret: Hmrc::BankValidations.configuration.client_secret,
        http_client: Hmrc::BankValidations.configuration.http_client,
        logger: Hmrc::BankValidations.configuration.logger
      )
        super(
          base_url: base_url,
          client_id: client_id,
          client_secret: client_secret,
          http_client: http_client,
          logger: logger
        )
      end

      def verify_personal_bank_account(sort_code, account_number, name, timeout: nil)
        refresh_token_if_required!(timeout: timeout)

        payload = {
          account: {
            sortCode: sort_code,
            accountNumber: account_number
          },
          subject: {
            name: name
          }
        }.to_json

        response = post_request(
          "/misc/bank-account/verify/personal",
          payload,
          request_headers,
          timeout: timeout
        )

        BankAccountVerificationResponse.new(response)
      rescue ResponseError => e
        # refreshing the token failed
        BankAccountVerificationResponse.new(e.response)
      end

      private

      attr_accessor :base_url, :client_id, :client_secret, :http_client, :logger, :token, :token_expiry

      def refresh_token_if_required!(timeout:)
        return unless token_invalid?

        request_time = Time.zone.now
        response = post_request!(
          "/oauth/token",
          token_request_payload,
          timeout: timeout
        )

        body = JSON.parse(response.body)

        self.token = body["access_token"]
        self.token_expiry = request_time + body["expires_in"]
      end

      def token_invalid?
        !token.present? || !token_expiry.present? || (token_expiry < Time.zone.now - 1.minute)
      end

      def token_request_payload
        {
          grant_type: "client_credentials",
          client_id: client_id,
          client_secret: client_secret
        }
      end

      def request_headers
        {
          "Content-Type" => "application/json",
          "Accept" => "application/vnd.hmrc.1.0+json",
          "User-Agent" => "dfe-claim-additional-payments",
          "Authorization" => "Bearer #{token}"
        }
      end

    end
  end
end

Hmrc::Client = Hmrc::BankValidations::Client unless defined?(Hmrc::Client)
