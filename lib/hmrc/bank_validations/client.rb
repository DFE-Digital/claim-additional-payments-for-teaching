module Hmrc
  module BankValidations
    def self.client
      @client ||= Client.new
    end

    def self.client=(client)
      @client = client
    end

    def self.configuration
      @configuration ||= Configuration.new
    end

    def self.configure
      yield(configuration) if block_given?
    end

    class Client < Hmrc::BaseClient
      def initialize(
        base_url: BankValidations.configuration.base_url,
        client_id: BankValidations.configuration.client_id,
        client_secret: BankValidations.configuration.client_secret,
        http_client: BankValidations.configuration.http_client,
        logger: BankValidations.configuration.logger
      )
        super
      end

      def verify_personal_bank_account(sort_code, account_number, name, timeout: nil)
        refresh_token_if_required!(timeout: timeout)

        request = PersonalBankAccountVerificationRequest.new(
          sort_code: sort_code,
          account_number: account_number,
          name: name
        )

        response = post_request!(
          request.path,
          request.payload,
          request.headers(token: token),
          timeout: timeout
        )

        BankAccountVerificationResponse.new(response)
      rescue ResponseError => e
        BankAccountVerificationResponse.new(e.response)
      end

      private

      attr_accessor :token, :token_expiry

      def refresh_token_if_required!(timeout:)
        return unless token_invalid?

        response = post_request!(
          "/oauth/token",
          token_request_payload,
          timeout: timeout
        )

        body = JSON.parse(response.body)

        self.token = body.fetch("access_token")
        self.token_expiry = Time.current + body.fetch("expires_in").to_i
      end

      def token_invalid?
        token.blank? || token_expiry.blank? || token_expiry < Time.current - 1.minute
      end

      def token_request_payload
        {
          grant_type: "client_credentials",
          client_id: client_id,
          client_secret: client_secret
        }
      end
    end
  end
end
