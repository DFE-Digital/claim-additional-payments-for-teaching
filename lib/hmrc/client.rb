module Hmrc
  class Client
    def initialize(
      base_url: Hmrc.configuration.base_url,
      client_id: Hmrc.configuration.client_id,
      client_secret: Hmrc.configuration.client_secret,
      http_client: Hmrc.configuration.http_client,
      logger: Hmrc.configuration.logger
    )
      self.base_url = base_url
      self.client_id = client_id
      self.client_secret = client_secret
      self.http_client = http_client
      self.logger = logger
    end

    def verify_personal_bank_account(sort_code, account_number, name)
      refresh_token_if_required

      payload = {
        account: {
          sortCode: sort_code,
          accountNumber: account_number
        },
        subject: {
          name: name
        }
      }.to_json

      response = post_request("/misc/bank-account/verify/personal", payload, request_headers)

      BankAccountVerificationResponse.new(response)
    end

    private

    attr_accessor :base_url, :client_id, :client_secret, :http_client, :logger, :token, :token_expiry

    def refresh_token_if_required
      return unless token_invalid?

      request_time = Time.zone.now
      response = post_request("/oauth/token", token_request_payload)

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

    def post_request(path, payload, headers = nil)
      response = http_client.post(
        "#{base_url}#{path}",
        payload,
        headers
      )

      if !response.success?
        logger.info("HMRC API error: response code #{response.status}")
        raise ResponseError.new(response)
      end

      response
    end
  end
end
