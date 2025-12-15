require "rails_helper"

RSpec.describe Hmrc::Client do
  let(:base_url) { "test" }
  let(:client_id) { "test" }
  let(:client_secret) { "test" }
  let(:http_client) { double }
  let(:logger) { double(info: nil) }
  let(:token) { "test_token" }
  let(:token_expiry) { 99999 }

  before do
    allow(http_client).to receive(:post).with("#{base_url}/oauth/token", {
      grant_type: "client_credentials",
      client_id: client_id,
      client_secret: client_secret
    }, nil) do
      double(success?: true, status: 200, body: {
        "access_token" => token,
        "expires_in" => token_expiry
      }.to_json)
    end
  end

  subject(:client) { described_class.new(base_url: base_url, client_id: "test", client_secret: "test", http_client: http_client, logger: logger) }

  describe "#initialize" do
    context "with parameters" do
      it "sets the client configuration to the supplied values" do
        expect(client.instance_variable_get(:@base_url)).to eq(base_url)
        expect(client.instance_variable_get(:@client_id)).to eq(client_id)
        expect(client.instance_variable_get(:@client_secret)).to eq(client_secret)
        expect(client.instance_variable_get(:@http_client)).to eq(http_client)
        expect(client.instance_variable_get(:@logger)).to eq(logger)
      end
    end

    context "without parameters" do
      subject(:client) { described_class.new }

      it "sets the client configuration to the default values" do
        expect(ENV["HMRC_API_BASE_URL"]).to be_a(String)
        expect(ENV["HMRC_API_CLIENT_ID"]).to be_a(String)
        expect(ENV["HMRC_API_CLIENT_SECRET"]).to be_a(String)

        expect(client.instance_variable_get(:@base_url)).to eq(ENV["HMRC_API_BASE_URL"])
        expect(client.instance_variable_get(:@client_id)).to eq(ENV["HMRC_API_CLIENT_ID"])
        expect(client.instance_variable_get(:@client_secret)).to eq(ENV["HMRC_API_CLIENT_SECRET"])
        expect(client.instance_variable_get(:@http_client)).to eq(Faraday)
        expect(client.instance_variable_get(:@logger)).to eq(Rails.logger)
      end
    end
  end

  describe "#verify_personal_bank_account" do
    let(:sort_code) { "999999" }
    let(:account_number) { "00000000" }
    let(:name) { Faker::Name.name }
    let(:expected_payload) do
      {
        account: {
          sortCode: sort_code,
          accountNumber: account_number
        },
        subject: {
          name: name
        }
      }.to_json
    end
    let(:expected_headers) do
      {
        "Content-Type" => "application/json",
        "Accept" => "application/vnd.hmrc.1.0+json",
        "User-Agent" => "dfe-claim-additional-payments",
        "Authorization" => "Bearer #{token}"
      }
    end
    let(:response_code) { 200 }
    let(:response_success) { true }
    let(:response_to_return) do
      {
        sortCodeIsPresentOnEISCD: "yes",
        accountNumberIsWellFormatted: "yes",
        nameMatches: "indeterminate",
        accountExists: "indeterminate"
      }.to_json
    end

    before do
      allow(http_client).to receive(:post).with("#{base_url}/misc/bank-account/verify/personal", expected_payload, expected_headers) do
        double(body: response_to_return, success?: response_success, status: response_code)
      end
    end

    subject(:response) { client.verify_personal_bank_account(sort_code, account_number, name) }

    context "with no token already retrieved" do
      it "saves the token and its expiry" do
        freeze_time do
          response
          expect(client.instance_variable_get(:@token)).to eq(token)
          expect(client.instance_variable_get(:@token_expiry)).to eq(Time.zone.now + token_expiry)
        end
      end

      it "sends a well-formed request to the HMRC API" do
        response
        expect(http_client).to have_received(:post).with("#{base_url}/misc/bank-account/verify/personal", expected_payload, expected_headers)
      end

      it "returns the expected object" do
        expect(response).to be_a Hmrc::BankAccountVerificationResponse
      end
    end

    context "when there is already a token retrieved" do
      before do
        client.instance_variable_set(:@token, token)
        client.instance_variable_set(:@token_expiry, Time.zone.now + token_expiry)
      end

      it "does not request a new token" do
        response
        expect(http_client).not_to have_received(:post).with("#{base_url}/oauth/token", an_instance_of(Hash), nil)
      end
    end

    context "when there is a response error" do
      let(:response_code) { 429 }
      let(:response_success) { false }
      let(:response_to_return) { "" }

      it "raises an error" do
        expect { response }.to raise_error(Hmrc::ResponseError)
      end
    end
  end
end
