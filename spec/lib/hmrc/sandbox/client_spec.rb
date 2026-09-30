require "rails_helper"
require Rails.root.join("lib/hmrc/sandbox/client")

RSpec.describe Hmrc::Sandbox::Client do
  it "matches an individual using v2 headers and returns the match link" do
    client = described_class.new(base_url: described_class::BASE_URL, client_id: "id", client_secret: "secret", totp_secret: nil, output: StringIO.new)
    allow(client).to receive(:access_token).with(timeout: 30).and_return("token")
    result = {"_links" => {"individual" => {"href" => "/individuals/matching/match-123"}}}
    request = stub_request(:post, "#{described_class::BASE_URL}/individuals/matching/")
      .with(body: {firstName: "Jane", lastName: "Smith", nino: "AA123456A", dateOfBirth: "1990-01-01"}.to_json,
        headers: {"Authorization" => "Bearer token", "Accept" => "application/vnd.hmrc.2.0+json", "Content-Type" => "application/json", "CorrelationId" => /\A[0-9a-f-]{36}\z/})
      .to_return(body: result.to_json)

    expect(client.match_user(first_name: "Jane", last_name: "Smith", nino: "AA123456A", date_of_birth: "1990-01-01")).to eq(result)
    expect(request).to have_been_requested.once
  end

  it "returns no match for MATCHING_FAILED" do
    client = described_class.new(base_url: described_class::BASE_URL, client_id: "id", client_secret: "secret", totp_secret: nil, output: StringIO.new)
    allow(client).to receive(:access_token).and_return("token")
    stub_request(:post, "#{described_class::BASE_URL}/individuals/matching/")
      .to_return(status: 404, body: '{"code":"MATCHING_FAILED"}')

    expect(client.match_user(first_name: "Jane", last_name: "Smith", nino: "AA123456A", date_of_birth: "1990-01-01")).to be_nil
  end

  it "does not treat an unavailable matching endpoint as a non-match" do
    client = described_class.new(base_url: described_class::BASE_URL, client_id: "id", client_secret: "secret", totp_secret: nil, output: StringIO.new)
    allow(client).to receive(:access_token).and_return("token")
    stub_request(:post, "#{described_class::BASE_URL}/individuals/matching/")
      .to_return(status: 404, body: '{"code":"MATCHING_RESOURCE_NOT_FOUND"}')

    expect { client.match_user(first_name: "Jane", last_name: "Smith", nino: "AA123456A", date_of_birth: "1990-01-01") }
      .to raise_error(Hmrc::ResponseError, /MATCHING_RESOURCE_NOT_FOUND/)
  end

  it "checks available services using application authentication and the v1 Accept header" do
    output = StringIO.new
    client = described_class.new(base_url: described_class::BASE_URL, client_id: "id", client_secret: "secret", totp_secret: nil, output: output)
    stub_request(:post, "#{described_class::BASE_URL}/oauth/token")
      .with(body: {grant_type: "client_credentials", scope: "assigned", client_id: "id", client_secret: "secret"})
      .to_return(body: {access_token: "token", expires_in: 3600}.to_json)
    services = [{"key" => "national-insurance", "name" => "National Insurance", "allowedUserTypes" => ["INDIVIDUAL"]}]
    request = stub_request(:get, "#{described_class::BASE_URL}/create-test-user/services")
      .with(headers: {"Authorization" => "Bearer token", "Accept" => "application/vnd.hmrc.1.0+json"})
      .to_return(body: services.to_json)

    expect(client.services).to eq(services)
    expect(request).to have_been_requested.once
    expect(output.string).to include("GET #{described_class::BASE_URL}/create-test-user/services -> HTTP 200")
  end

  it "logs the endpoint and HTTP status for OAuth success and a forbidden API response without credentials" do
    output = StringIO.new
    client = described_class.new(base_url: described_class::BASE_URL, client_id: "private-id", client_secret: "private-secret", totp_secret: nil, output: output)
    stub_request(:post, "#{described_class::BASE_URL}/oauth/token")
      .to_return(body: {access_token: "private-token", expires_in: 3600}.to_json)
    stub_request(:post, "#{described_class::BASE_URL}/create-test-user/individuals")
      .to_return(status: 403, body: '{"code":"FORBIDDEN","message":"This endpoint is not available"}')

    expect { client.create_user }.to raise_error(Hmrc::ResponseError, /FORBIDDEN/)
    expect(output.string).to include("POST #{described_class::BASE_URL}/oauth/token -> HTTP 200")
    expect(output.string).to include("POST #{described_class::BASE_URL}/create-test-user/individuals -> HTTP 403")
    expect(output.string).not_to include("private-id", "private-secret", "private-token", "serviceNames")
  end

  it "logs GET endpoints when fetching employment history" do
    output = StringIO.new
    client = described_class.new(base_url: described_class::BASE_URL, client_id: "id", client_secret: "secret", totp_secret: nil, output: output)
    allow(client).to receive(:access_token).and_return("token")
    stub_request(:get, "#{described_class::BASE_URL}/individuals/employments/paye")
      .with(query: {matchId: "match-123", fromDate: "2025-01-01"})
      .to_return(body: '{"employments":[]}')

    client.employment_history(match_id: "match-123", from_date: "2025-01-01")

    expect(output.string).to include("GET #{described_class::BASE_URL}/individuals/employments/paye?matchId=match-123&fromDate=2025-01-01 -> HTTP 200")
  end

  it "prefixes the secret with an eight-digit SHA512 OTP and requests assigned scope when seeding employments" do
    travel_to Time.utc(2026, 9, 30, 12) do
      secret = "JBSWY3DPEHPK3PXP"
      otp = ROTP::TOTP.new(secret, digits: 8, digest: "sha512", interval: 30).now
      client = described_class.new(base_url: described_class::BASE_URL, client_id: "id", client_secret: "secret", totp_secret: secret)
      token_request = stub_request(:post, "#{described_class::BASE_URL}/oauth/token")
        .with(body: {grant_type: "client_credentials", scope: "assigned", client_id: "id", client_secret: "#{otp}secret"})
        .to_return(body: {access_token: "token", expires_in: 3600}.to_json)
      employment_request = stub_request(:post, "#{described_class::BASE_URL}/individuals/integration-framework-test-support/individuals/employment/nino/AA123456A")
        .with(query: {useCase: "DFE"}, headers: {"Authorization" => "Bearer token"})
        .to_return(status: 201, body: '{"employments":[]}')

      expect(client.create_employments(nino: "AA123456A", payload: {employments: []})).to eq("employments" => [])
      expect(token_request).to have_been_requested.once
      expect(employment_request).to have_been_requested.once
    end
  end

  it "creates an individual with only National Insurance enrolment using application authentication" do
    client = described_class.new(base_url: described_class::BASE_URL, client_id: "id", client_secret: "secret", totp_secret: nil)
    token = stub_request(:post, "#{described_class::BASE_URL}/oauth/token")
      .with(body: {grant_type: "client_credentials", scope: "assigned", client_id: "id", client_secret: "secret"})
      .to_return(body: {access_token: "token", expires_in: 3600}.to_json)
    request = stub_request(:post, "#{described_class::BASE_URL}/create-test-user/individuals")
      .with(body: {serviceNames: ["national-insurance"], nino: "AA123456A"}.to_json,
        headers: {"Authorization" => "Bearer token", "Accept" => "application/vnd.hmrc.1.0+json", "Content-Type" => "application/json"})
      .to_return(status: 201, body: {nino: "AA123456A"}.to_json)

    expect(client.create_user(nino: "AA123456A")).to eq("nino" => "AA123456A")
    expect(token).to have_been_requested.once
    expect(request).to have_been_requested.once
  end

  it "seeds DFE employment data with the requested date range and v1 headers" do
    client = described_class.new(base_url: described_class::BASE_URL, client_id: "id", client_secret: "secret", totp_secret: nil)
    allow(client).to receive(:access_token).and_return("token")
    payload = {"employments" => []}
    request = stub_request(:post, "#{described_class::BASE_URL}/individuals/integration-framework-test-support/individuals/employment/nino/AA123456A")
      .with(query: {useCase: "DFE", startDate: "2025-01-01", endDate: "2026-01-01"}, body: payload.to_json,
        headers: {"Authorization" => "Bearer token", "Accept" => "application/vnd.hmrc.1.0+json"})
      .to_return(status: 201, body: payload.to_json)

    expect(client.create_employments(nino: "AA123456A", payload: payload, from_date: "2025-01-01", to_date: "2026-01-01")).to eq(payload)
    expect(request).to have_been_requested.once
  end

  it "surfaces HMRC errors without retrying a write" do
    client = described_class.new(base_url: described_class::BASE_URL, client_id: "id", client_secret: "secret", totp_secret: nil)
    allow(client).to receive(:access_token).and_return("token")
    request = stub_request(:post, "#{described_class::BASE_URL}/create-test-user/individuals")
      .to_return(status: 400, body: '{"code":"INVALID_REQUEST"}')

    expect { client.create_user }.to raise_error(Hmrc::ResponseError, /INVALID_REQUEST/)
    expect(request).to have_been_requested.once
  end

  it "refuses production URLs before making any requests" do
    expect { described_class.new(base_url: "https://api.service.hmrc.gov.uk", client_id: "id", client_secret: "secret") }
      .to raise_error(ArgumentError, /HMRC_EMPLOYMENTS_BASE_URL/)
  end
end
