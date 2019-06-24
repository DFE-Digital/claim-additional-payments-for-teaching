require "verify/service_provider"

def stub_vsp_generate_request
  stub_request(:post, Verify::ServiceProvider::GENERATE_REQUEST_URL)
    .with(headers: {"Content-Type" => "application/json"})
    .to_return(status: 200, body: stubbed_auth_request_response.to_json, headers: {})
end

def stubbed_auth_request_response
  {
    "samlRequest" => "PD94bWwg",
    "requestId" => "REQUEST_ID",
    "ssoLocation" => "/verify/fake_sso",
  }
end
