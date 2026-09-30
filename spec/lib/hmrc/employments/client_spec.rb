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
          scope: "assigned",
          client_id: client_id,
          client_secret: "#{totp_value}#{client_secret}"
        },
        {
          "Accept" => "application/json",
          "Content-Type" => "application/x-www-form-urlencoded",
          "User-Agent" => "dfe-claim-additional-payments"
        }
      ).and_return(first_response, second_response)

      expect(client.send(:access_token)).to eq("old-token")

      client.instance_variable_set(:@access_token_expiry, Time.current - 1)

      expect(client.send(:access_token)).to eq("new-token")
    end
  end

  describe "#employment_history_for_individual" do
    before do
      allow(ROTP::TOTP).to receive(:new).with(
        totp_secret,
        digits: 8,
        digest: "sha512",
        interval: 30
      ).and_return(instance_double(ROTP::TOTP, at: totp_value))
    end

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

      matching_response = double(success?: true, status: 200, body: {"_links" => {"individual" => {"href" => "/individuals/matching/match-123"}}}.to_json)
      employment_response = double(success?: true, status: 200, body: expected_response.to_json)

      allow(client).to receive(:access_token).and_return("access-token")
      allow(client).to receive(:post_request!).and_call_original
      allow(client).to receive(:post_request!).with(
        "/individuals/matching/",
        anything,
        anything,
        timeout: nil
      ).and_return(matching_response)
      allow(client).to receive(:get_request!).with(
        "/individuals/employments/paye?matchId=match-123&fromDate=2024-01-01&toDate=2024-03-31&payeReference=#{CGI.escape("123/AB45678")}",
        anything,
        timeout: nil
      ).and_return(employment_response)

      response = client.employment_history_for_individual(
        first_name: "Ida",
        last_name: "Goodman",
        nino: "XP578353A",
        date_of_birth: "1980-01-01",
        from_date: "2024-01-01",
        to_date: "2024-03-31",
        paye_reference: "123/AB45678",
        correlation_id: "cascade-correlation-id"
      )

      expect(response).to eq(employment_response)
      expect(response.success?).to be(true)
      expect(response.status).to eq(200)
      expect(response.body).to eq(expected_response.to_json)
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

    it "returns the raw employment response object for the matched individual" do
      response = client.employment_history(
        match_id: match_id,
        from_date: from_date,
        to_date: to_date,
        paye_reference: paye_reference,
        correlation_id: correlation_id
      )

      expect(response).to be_a(Object)
      expect(response.body).to include("employments")
    end
  end
end
