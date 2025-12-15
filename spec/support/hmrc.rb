RSpec.shared_context "with stubbed HMRC client", shared_context: :metadata do
  let(:hmrc_response) do
    double(
      name_match?: name_match,
      sort_code_correct?: sort_code_correct,
      account_exists?: account_exists,
      code: 200,
      success?: name_match && account_exists && sort_code_correct,
      body: "Test response"
    )
  end

  let(:hmrc_client) { double(verify_personal_bank_account: hmrc_response) }
  let(:name_match) { true }
  let(:account_exists) { true }
  let(:sort_code_correct) { true }

  before do
    @old_hmrc_client = Hmrc.client
    Hmrc.client = hmrc_client
  end

  after { Hmrc.client = @old_hmrc_client }
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
    @old_hmrc_client = Hmrc.client
    Hmrc.configure { |config| config.http_client = double(post: double(success?: false, status: 429, body: "Test failure", code: 429)) }
    Hmrc.client = Hmrc::Client.new
  end

  after do
    Hmrc.configure { |config| config.http_client = Faraday }
    Hmrc.client = @old_hmrc_client
  end
end

RSpec.configure do |rspec|
  rspec.include_context "with stubbed HMRC client", with_stubbed_hmrc_client: true
  rspec.include_context "with HMRC bank validation enabled", with_hmrc_bank_validation_enabled: true
  rspec.include_context "with failing HMRC bank validation API request", with_failing_hmrc_bank_validation: true
end
