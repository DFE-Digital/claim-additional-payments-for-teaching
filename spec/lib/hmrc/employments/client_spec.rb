require "rails_helper"

RSpec.describe Hmrc::Employments::Client do
  let(:base_url) { "https://example.test" }
  let(:client_id) { "client-id" }
  let(:client_secret) { "client-secret" }
  let(:totp_secret) { "totp-secret" }
  let(:http_client) { double }
  let(:logger) { double(info: nil) }
  let(:totp_value) { "123456" }

  subject(:client) do
    described_class.new(
      base_url: base_url,
      client_id: client_id,
      client_secret: client_secret,
      totp_secret: totp_secret,
      http_client: http_client,
      logger: logger
    )
  end

  describe "#fetch_access_token" do
    before do
      allow(ROTP::TOTP).to receive(:new).with(
        totp_secret,
        digits: 8,
        digest: "sha512",
        interval: 30
      ).and_return(instance_double(ROTP::TOTP, at: totp_value))
      allow(http_client).to receive(:post).with(
        "#{base_url}/oauth/token",
        {
          grant_type: "client_credentials",
          client_id: client_id,
          client_secret: "#{totp_value}#{client_secret}"
        },
        {
          "Accept" => "application/json",
          "Content-Type" => "application/x-www-form-urlencoded",
          "User-Agent" => "dfe-claim-additional-payments"
        }
      ).and_return(double(success?: true, status: 200, body: {"access_token" => "abc123", "expires_in" => 14400}.to_json))
    end

    it "uses the current TOTP in the client secret and returns the access token" do
      expect(client.fetch_access_token).to eq("abc123")
    end
  end

  describe "#authenticated_headers" do
    before do
      allow(ROTP::TOTP).to receive(:new).with(
        totp_secret,
        digits: 8,
        digest: "sha512",
        interval: 30
      ).and_return(instance_double(ROTP::TOTP, at: totp_value))
      allow(http_client).to receive(:post).with(
        "#{base_url}/oauth/token",
        {
          grant_type: "client_credentials",
          client_id: client_id,
          client_secret: "#{totp_value}#{client_secret}"
        },
        {
          "Accept" => "application/json",
          "Content-Type" => "application/x-www-form-urlencoded",
          "User-Agent" => "dfe-claim-additional-payments"
        }
      ).and_return(double(success?: true, status: 200, body: {"access_token" => "abc123", "expires_in" => 14400}.to_json))
    end

    it "returns bearer auth headers for downstream HMRC requests" do
      expect(client.authenticated_headers).to eq(
        {
          "Authorization" => "Bearer abc123",
          "Accept" => "application/json"
        }
      )
    end
  end

  describe "#access_token" do
    it "refreshes the token when it has expired" do
      allow(ROTP::TOTP).to receive(:new).with(
        totp_secret,
        digits: 8,
        digest: "sha512",
        interval: 30
      ).and_return(instance_double(ROTP::TOTP, at: totp_value))

      first_response = double(success?: true, status: 200, body: {"access_token" => "old-token", "expires_in" => 1}.to_json)
      second_response = double(success?: true, status: 200, body: {"access_token" => "new-token", "expires_in" => 14400}.to_json)

      allow(http_client).to receive(:post).with(
        "#{base_url}/oauth/token",
        {
          grant_type: "client_credentials",
          client_id: client_id,
          client_secret: "#{totp_value}#{client_secret}"
        },
        {
          "Accept" => "application/json",
          "Content-Type" => "application/x-www-form-urlencoded",
          "User-Agent" => "dfe-claim-additional-payments"
        }
      ).and_return(first_response, second_response)

      expect(client.access_token).to eq("old-token")

      client.instance_variable_set(:@access_token_expiry, Time.current - 1)

      expect(client.access_token).to eq("new-token")
    end
  end

  describe "#match_individual" do
    let(:correlation_id) { "58072660-1df9-4deb-b4ca-cd2d7f96e480" }
    let(:payload) do
      {
        firstName: "Ida",
        lastName: "Goodman",
        nino: "XP578353A",
        dateOfBirth: "1980-01-01"
      }
    end

    before do
      allow(ROTP::TOTP).to receive(:new).with(
        totp_secret,
        digits: 8,
        digest: "sha512",
        interval: 30
      ).and_return(instance_double(ROTP::TOTP, at: totp_value))

      allow(http_client).to receive(:post).with(
        "#{base_url}/individuals/matching/",
        payload.to_json,
        {
          "Authorization" => "Bearer access-token",
          "Accept" => "application/vnd.hmrc.2.0+json",
          "CorrelationId" => correlation_id,
          "Content-Type" => "application/json"
        }
      ).and_return(double(success?: true, status: 200, body: {"_links" => {"individual" => {"href" => "/individuals/matching/c5ff392d-59b9-498b-83e7-c7c4ebfb6220"}}}.to_json))

      allow(client).to receive(:access_token).and_return("access-token")
    end

    it "returns the matched individual's reference id" do
      expect(
        client.match_individual(
          first_name: "Ida",
          last_name: "Goodman",
          nino: "XP578353A",
          date_of_birth: "1980-01-01",
          correlation_id: correlation_id
        )
      ).to eq("c5ff392d-59b9-498b-83e7-c7c4ebfb6220")
    end
  end

  describe "#employment_history_for_individual" do
    it "matches the individual and then fetches their employment history" do
      client = described_class.new(
        base_url: base_url,
        client_id: client_id,
        client_secret: client_secret,
        totp_secret: totp_secret,
        http_client: http_client,
        logger: logger
      )

      expected_response = {"employments" => [{"payeReference" => "123/AB45678"}]}

      allow(client).to receive(:match_individual).with(
        first_name: "Ida",
        last_name: "Goodman",
        nino: "XP578353A",
        date_of_birth: "1980-01-01",
        correlation_id: "cascade-correlation-id",
        timeout: nil
      ).and_return("match-123")

      allow(client).to receive(:employment_history).with(
        match_id: "match-123",
        from_date: "2024-01-01",
        to_date: "2024-03-31",
        paye_reference: "123/AB45678",
        correlation_id: "cascade-correlation-id",
        timeout: nil
      ).and_return(expected_response)

      expect(
        client.employment_history_for_individual(
          first_name: "Ida",
          last_name: "Goodman",
          nino: "XP578353A",
          date_of_birth: "1980-01-01",
          from_date: "2024-01-01",
          to_date: "2024-03-31",
          paye_reference: "123/AB45678",
          correlation_id: "cascade-correlation-id"
        )
      ).to eq(expected_response)
    end
  end

  describe "#employment_history" do
    let(:correlation_id) { "58072660-1df9-4deb-b4ca-cd2d7f96e480" }
    let(:match_id) { "ddacdb43-9f39-4faf-b8c3-8e8105f4de1e" }
    let(:from_date) { "2024-01-01" }
    let(:to_date) { "2024-03-31" }
    let(:paye_reference) { "123/AB45678" }
    let(:response_body) do
      {
        "employments" => [
          {"payeReference" => paye_reference, "employmentStatus" => "Employed"}
        ]
      }.to_json
    end

    before do
      allow(ROTP::TOTP).to receive(:new).with(
        totp_secret,
        digits: 8,
        digest: "sha512",
        interval: 30
      ).and_return(instance_double(ROTP::TOTP, at: totp_value))

      allow(client).to receive(:access_token).and_return("access-token")

      allow(http_client).to receive(:get).with(
        "#{base_url}/individuals/employments/paye?matchId=#{match_id}&fromDate=#{from_date}&toDate=#{to_date}&payeReference=#{CGI.escape(paye_reference)}",
        nil,
        {
          "Authorization" => "Bearer access-token",
          "Accept" => "application/vnd.hmrc.2.0+json",
          "CorrelationId" => correlation_id
        }
      ).and_return(double(success?: true, status: 200, body: response_body))
    end

    it "returns the employment json object for the matched individual" do
      expect(
        client.employment_history(
          match_id: match_id,
          from_date: from_date,
          to_date: to_date,
          paye_reference: paye_reference,
          correlation_id: correlation_id
        )
      ).to eq(JSON.parse(response_body))
    end
  end
end
