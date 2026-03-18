HMRC_TEST_BASE_URL = "https://test-api.service.hmrc.gov.uk"

RSpec.shared_context "with stubbed HMRC client", shared_context: :metadata do
  let(:name_match) { true }
  let(:account_exists) { true }
  let(:sort_code_correct) { true }

  let(:hmrc_bank_verification_response_body) do
    {
      sortCodeIsPresentOnEISCD: sort_code_correct ? "yes" : "no",
      accountExists: account_exists ? "yes" : "no",
      nameMatches: name_match ? "yes" : "no"
    }.to_json
  end

  before do
    @old_base_url = Hmrc.configuration.base_url
    Hmrc.configuration.base_url = HMRC_TEST_BASE_URL

    stub_request(:post, "#{HMRC_TEST_BASE_URL}/oauth/token")
      .to_return(
        status: 200,
        body: {access_token: "test-token", expires_in: 3600}.to_json,
        headers: {"Content-Type" => "application/json"}
      )

    stub_request(:post, "#{HMRC_TEST_BASE_URL}/misc/bank-account/verify/personal")
      .to_return(
        status: 200,
        body: hmrc_bank_verification_response_body,
        headers: {"Content-Type" => "application/json"}
      )
  end

  after do
    Hmrc.configuration.base_url = @old_base_url
  end
end

RSpec.shared_context "with HMRC bank validation enabled", shared_context: :metadata do
  before do
    Hmrc.configure { |config| config.enabled = true }
  end

  after do
    Hmrc.configure { |config| config.enabled = false }
  end
end

RSpec.shared_context "with failing HMRC bank validation API request", shared_context: :metadata do
  before do
    @old_base_url = Hmrc.configuration.base_url
    Hmrc.configuration.base_url = HMRC_TEST_BASE_URL

    Hmrc.client.send(:token=, nil)

    stub_request(:post, "#{HMRC_TEST_BASE_URL}/oauth/token")
      .to_return(status: 429, body: "Test failure")
  end

  after do
    Hmrc.configuration.base_url = @old_base_url
  end
end

RSpec.configure do |rspec|
  rspec.include_context "with stubbed HMRC client", with_stubbed_hmrc_client: true
  rspec.include_context "with HMRC bank validation enabled", with_hmrc_bank_validation_enabled: true
  rspec.include_context "with failing HMRC bank validation API request", with_failing_hmrc_bank_validation: true
end
